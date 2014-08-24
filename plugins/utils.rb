#encoding=utf-8

puts "TODO: Calculations with time in the UtilsPlugin."

def levenshtein(s, t)
  m = s.length
  n = t.length
  return m if n == 0
  return n if m == 0
  d = Array.new(m+1) {Array.new(n+1)}

  (0..m).each {|i| d[i][0] = i}
  (0..n).each {|j| d[0][j] = j}
  (1..n).each do |j|
    (1..m).each do |i|
      d[i][j] = if s[i-1] == t[j-1]  # adjust index into string
                  d[i-1][j-1]       # no operation required
                else
                  [ d[i-1][j]+1,    # deletion
                    d[i][j-1]+1,    # insertion
                    d[i-1][j-1]+1,  # substitution
                  ].min
                end
    end
  end
  d[m][n]
end

$DO_BROAD_QUERY = true
module UtilsPlugin
  class Plugin < PluginBase
    init_v2 :utils
    
    meta :name => "Utils Plugin",
         :author => "Alexander Rath",
         :version => 0.4,
         :description => "A nifty plugin. Remind Alex to tell Paul to put a @time function in his plugin and make it a GeoPlugin."
    
    cmd :calc, "Calculate an expression.", "@calc e^5 - sin(20°)e / pi*4" # or 4GB [kB] => 4,000,000kB
    cmd :count, "Count words/lines/characters in a text.", "@count Hello, World!"
    cmd :brb, "Be away", "@brb Getting food"
    cmd :back, "Be back", "@back"
    cmd :whereis, "Where is somebody?", "@whereis irath96"
    cmd :who?, "Who is active?", "@who?"
    
    cmd :who, "Scan the chatlog", "@who is awesome?"
    cmd :what, "Same as @who", "@what is great?"
    cmd :rand, "Get a random number.", "@rand 100"
    
    # TODO: Put this in the MemoPlugin?
    cmd :todo, "Remember a todo.", "@todo Feed goldfish"
    cmd :todo?, "List todos", "@todo?"
    
    @@users = {}
    @@reduce = {}
      
    hook:msg do |msg|
      #msg.get_cached(:body, :chatname, :from_handle) do |b, c, fh|
        unless msg.body.match(/^\$back/)
          if @@reduce[msg.user] != msg.user.name # The username changed!
            @@users.delete @@reduce[msg.user]
            @@reduce.delete msg.user
          end
          
          @@reduce[msg.user] = msg.user.name
          
          unless @@users[msg.user.name] == nil
            state, since, arg = @@users[msg.user.name]
            cmd_back true, msg.user, msg if state == :away
          end
          
          @@users[msg.user.name] = [ :msg, Time.now.to_f, msg.body ]
        end
        
        unless @@users[msg.user.name] == nil
          state, since, arg = @@users[msg.user.name]
          
          rt = Time.now.to_f - since
          msg.chat.push "Good morning, #{msg.user.name}!" if rt > 600
        end
        
        tbod = '  ' + msg.body + '  '
        tbod.gsub! /-/, ' '
        tbod.gsub! /\sim\s/i, ' I\'m '
        tbod.gsub! /'ll/i, ' will'
        tbod.gsub! /'re/i, ' are'
        tbod.gsub! /'ve/i, ' have'
        tbod.gsub! /'s\s/i, ' is '
        tbod.gsub! /cannot/i, 'can not'
        tbod.gsub! /can't/i, 'can not'
        tbod.gsub! /won't/i, 'will not'
        tbod.gsub! /n't/i, ' not'
        tbod.gsub! /\s(I|me)\s/i, ' '
        tbod.gsub! /have/i, 'has'
        tbod.gsub! /it's/i, 'it is'
        tbod.gsub! /\sam\s/i, ' is '
        
        tbod.gsub! /\s(is|are|has|have|did|had|quite|not|very|will|was|were|\w*thing)\s/i, ' '
        
        tbod.gsub! /es\s/i, ' '
        tbod.gsub! /[s]+\s/i, ' '
        tbod.gsub! /e\s/i, ' '
        
        se = tbod.split /[.!?:\]\[\"]/ # "
        se.each do |sentence|
          sentence = sentence.chomp.strip.downcase
        ##puts sentence.inspect
          
          if sentence.length > 4
            values  = '" ' + $mysql.escape_string(sentence.split(' ').sort.uniq.join(' ')) + '",'
            values += '" ' + $mysql.escape_string(sentence) + ' ",'
            values += '"' + $mysql.escape_string(msg.body) + '",'
            values += '"' + $mysql.escape_string(msg.user.name) + '",'
            values += Time.now.to_i.to_s + ','
            values += '"' + $mysql.escape_string(msg.chat.name) + '"'
            
            $mysql.query "INSERT INTO learn (`raw`, `ident`, `sentence`, `handle`, `time`, `chatname`) VALUES (#{values})"
          end
        end
      #end
    end
    
    def self.cmd_who?
      plus_count = 0
      str = []
      @@users.each do |(user,(state,since,arg))|
        rt = Time.now.to_f - since
        t = rt.time_s
        
        if state == :away
          str << [ rt + 600, "[-] #{user}, away, has been \"#{arg}\" for #{t}" ]
        else
          if rt < 600
            str << [ rt - 600, "[+] #{user}, active, said \"#{arg}\" #{t} ago!" ]
            plus_count += 1
          else
            str << [ rt, "[-] #{user}, idle, said \"#{arg}\" #{t} ago!" ]
          end
        end
      end
      
      str.sort! { |a,b| a[0] <=> b[0] }
      notify ([''] + str.map { |a| a[1] }).join("\n  ")
      
      if plus_count == 1
        notify "You are... FOREVER ALONE!\n(Talking to ARI might cheer you up)"
      end
    end
    
    def self.cmd_brb
      @@reduce[process.owner] = process.owner.name
      @@users[process.owner.name] = [ :away, Time.now.to_f, data ]
    end
    
    def self.cmd_back(implicit=false, user=nil, _msg=nil)
      _msg = (_msg or msg)
      user = (user or process.owner)
      if @@users[user.name] == nil
        notify "Excuse me?"
      else
        state, since, arg = @@users[user.name]
        return unless state == :away
        
        t = (Time.now.to_f - since).time_s
        
        app = implicit ? ' apparently' : ''
        _msg.chat.push "#{user.name} has returned from being \"#{arg}\"#{app} after #{t}, hooray!"
        _msg.chat.push "Welcome back, #{user}!"
        
        @@users[user] = [ :here, Time.now.to_f, _msg.body ]
      end
    end
    
    def self.cmd_where?
      if @@users[data] == nil
        notify "Unknown."
      else
        state, since, arg = @@users[data]
        t = (Time.now.to_f - since).time_s
        
        notify case state
          when :here then "Used #{$CMD_SYMBOL}back #{t} ago."
          when :msg then "Said \"#{arg}\" #{t} ago."
          when :brb then "Is \"#{arg}\" for #{t}."
        end
      end
    end
    
    def self.cmd_what; cmd_who; end
    def self.cmd_who
      tbod = '  ' + data + '  '
      tbod.gsub! /-/, ' '
      tbod.gsub! /\?/, ' ? '
      tbod.gsub! /\sim\s/i, ' I\'m '
      tbod.gsub! /'ll/i, 'I will'
      tbod.gsub! /'re/i, ' are'
      tbod.gsub! /'ve/i, ' have'
      tbod.gsub! /'s\s/i, ' is '
      tbod.gsub! /cannot/i, 'can not'
      tbod.gsub! /can't/i, 'can not'
      tbod.gsub! /won't/i, 'will not'
      tbod.gsub! /n't/i, ' not'
      tbod.gsub! /\s(I|me)\s/i, ' '
      tbod.gsub! /have/i, 'has'
      tbod.gsub! /it's/i, 'it is'
      tbod.gsub! /\sam\s/i, ' is '
      
      tbod.gsub! /\s(is|are|has|have|did|had|quite|not|very|was|were|will|\w*thing)\s/i, ' '
      
      tbod.gsub! /es\s/i, ' '
      tbod.gsub! /[s]+\s/i, ' '
      tbod.gsub! /e\s/i, ' '
      
      tbod.gsub! /\s*\?\s*/, '%'
      tbod.gsub! /\s/, '%' if $DO_BROAD_QUERY
      tbod.gsub! /[%]+/, '%'
      
      hs = []
      
      puts tbod.inspect
      q = $mysql.query "SELECT * FROM `learn` WHERE ident LIKE \"" + $mysql.escape_string(tbod) + "\""
      
      while h = q.fetch_hash; hs << h; end
      q.free
      
      msg.chat.push '@who :-  ' + hs.map { |s| s['handle'] + ': ' + s['sentence'] }.join("\n")[0 .. 1000]
    end
    
    def self.cmd_calc
      degree = "\xC2\xB0".force_encoding('ascii-8bit')
      puts data.inspect
      puts data.gsub!(degree, "?")
      
      IO.popen("node ~/jison/examples/run.js raw", "r+") do |f|
        f.puts data
        f.close_write
        d = f.read
        msg.chat.push("@calc :-  Results:\n" + d.gsub("?", degree))
      end
    end
  end
  
  $u3s_original = Hash.new
  SkypeMessage.on(:change, :body) do |msg, key, o_body, n_body|
    unless o_body == nil
      msg.get_cached(:edited_by, :from_handle) do
        next if msg.is_local? or msg.edited_by == 'fremdpartikel2'
        
        $u3s_original[msg] = o_body if $u3s_original[msg] == nil
        next if levenshtein($u3s_original[msg].downcase, n_body.downcase) < 3 and not n_body.empty?
        
        o_body = $u3s_original[msg]
        $u3s_original[msg] = n_body
        
        obj = msg.edited_by == msg.from_handle ? 'her' : "#{msg.from_handle}'s"
        if n_body == ""
          msg.chat.push "** #{msg.edited_by} deleted #{obj} message \"#{o_body}\"."
        else
          msg.chat.push "** #{msg.edited_by} changed #{obj} message from \"#{o_body}\" to \"#{n_body}\""
        end
      end
    end
  end
end