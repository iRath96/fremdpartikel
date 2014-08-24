require "timeout"
require "levenshtein"

#
# Main code, the heart of Fremdpartikel.
#

$processes = {}
$pid_counter = 0

$root_user = HashResponder.new :uid => 'root://'
$root_process = FP::Process.new nil, nil, $root_user, 'fremdpartikel', 'run', { 'stdout' => FP::Pipe.new(STDOUT), 'x' => '42' }
$root_thread = Thread.current

$blnotified = Hash.new 0
$blist = []

def blacklisted?(handle); $blist.include? handle; end

def eval_cmd(msg, body, **params)
  raise "That's not a valid command." unless body[0 ... $CMD_SYMBOL.length] == $CMD_SYMBOL
  
  parent_thread = Thread.current
  parent_thread = $root_thread unless parent_thread.thread_variable?(:process)
  
  process = FP::Process.current
  
  if body[0...3] == '$& '
    body = body[3..-1]
    body.gsub!(/[^&]&([\+a-z0-9]+)/) { |i| i[0] + process.get_env_var(i[2..-1]) }
    body.gsub! '&&', '&'
  end
  
  cmd, data = body.split ' ', 2
  cname = cmd[$CMD_SYMBOL.length .. -1]
  
  if cname == 'env'
    var, val = data.split ' ', 2
    
    bmsg = FakeMessage.new msg, FakeChat.new(msg.chat)
    
    thread = eval_cmd bmsg, val
    thread.join if thread
    
    val = bmsg.chat.buffer.join "\n"
    process.set_env_var(var, val)
    
    return nil
  end
  
  cname = cname.force_encoding('utf-8')
  func = PluginBase[cname.to_sym]
  if func == nil
    best = PluginBase.commands.map { |(k,v)| [ k, Levenshtein.distance(cname, k.to_s) ] }.min { |a,b| a[1] <=> b[1] }
    msg.chat.push "Did you mean $#{best[0].to_s}? Learn to type."
  else
    return Thread.new do
      Terminator.register_thread Thread.current # Let Terminator know that this thread was created
      
      parent_process = process
      process = FP::Process.new msg.chat, parent_thread, (params[:as] or msg.user), cname, data
      
      process[:stdin] = (params[:stdin] or parent_process[:stdin] or msg.chat) # TODO: Does this make sense? I think so.
      process[:stdout] = (params[:stdout] or parent_process[:stdout] or msg.chat)
      
      process[:msg] = msg
      process[:data] = data
      
      process[:protocol] = params[:protocol]
      
      tout = cname == 'sam' ? 300 : 60
      tout = 3600 * 24 if cname == 'countdown' or cname == 'as'
      
      retried = false
      begin
        raise PermissionError if params[:with_rank] and params[:with_rank] < func.rank
        
        Quota.register :spawn, 1
        timeout(tout) { func.invoke(msg.user, msg, data) } # TODO: msg.from_handle is crap.
      rescue PermissionError => p
        if !msg.user.logged_in? and Quota.register(:warn, 10, :mode => :bool)
          if msg.user.account
            a = AccountAuthentication.auths_for_account msg.user.account
            a = a.find_all { |a| a.identity.rank >= func.rank } # We only want the ones with a high enough rank.
            if a.length > 0
              ident = a.sample.identity
              
              msg.chat.push "[core] Automatically logging you in as '#{ident.username}´."
              msg.chat.push "[core] (Warning: #{a.length} are accounts uid-assigned to you (rank #{func.rank}+), identity randomly chosen)." if a.length > 1
              
              msg.user.login ident # Magic.
              
              unless retried
                retried = true
                retry
              end
            end
          end
          msg.chat.push "[core] Permission-Error#{msg.user.logged_in? ? '' : ' (try logging in)'}"
        elsif msg.user.logged_in?
          msg.chat.push "[core] Permission-Error, you need to be #{func.rank} but are #{params[:with_rank] or msg.user.rank}."
        end
      rescue QuotaError => q
        msg.chat.push "[core] Quota-Error (#{q.type} for #{q.user.name rescue '?'})" if Quota.register :warn, 10, :mode => :bool
      rescue Timeout::Error => t
        msg.chat.push "[core] #{cmd} - The command timed out (#{tout} seconds), sorry."
      rescue => e
        msg.chat.push "[core] #{cmd} - Your command failed: #{e.inspect}"
        puts e.backtrace.inspect
      ensure
        process.kill
      end # begin
    end # Thread.new
  end # unless
  
  return nil
end

def register_message(msg, protocol=Protocol)
  # TODO: return if blacklisted...
  
  body = msg.body
  if body[0 ... $CMD_SYMBOL.length] == $CMD_SYMBOL
    #if blacklisted? msg.from_handle
    #  body = $CMD_SYMBOL + 'nil' # useless
    #  msg.chat.push "[core] Sorry, my dear, you are blacklisted." if (Time.now.to_f - $blnotified[msg.from_handle]) > 10
    #  $blnotified[msg.from_handle] = Time.now.to_f
    #  return
    #end
    
    eval_cmd msg, body, :protocol => protocol
  end
  
  PluginBase.singleton.fire :msg, '', msg
end

# TODO: Better solution?
AliasPlugin.load