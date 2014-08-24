puts "TODO: Enable people to activate a cost-less mode for non-private chats by polling."
puts "TODO: Write a TODO-Plugin."

module RootPlugin
  class UptimeManager
    @@total_uptime = 0
    @@session_count = 0
    
    include Persistence
    use_methods
    
    @@session_count += 1
    
    def self.total_uptime; @@total_uptime + Plugin.uptime; end
    def self.session_count; @@session_count; end
  end
  
  class Plugin < PluginBase
    init_v2 :root
    
    meta :name => "Root Plugin",
         :author => "Alexander Rath",
         :version => 1.6,
         :description => "A plugin that deals with system stuff and yeah, blah. Base commands, plugin commands 'n' stuff."
    
    cmd:'?', "What is this? Where am I? Ahhh!"
    cmd:'!', "Get some information."
    
    cmd:'', "Evaluate your default command (shortcut)"
    cmd:default, "Set your default command for the @ command.", "command_name"
    
    cmd:as, "Run a command as somebody else.", "username command+", :rank => :admin
    cmd:info, "Get information about the system"
    cmd:code, "Get information about the code of fremdpartikel"
    cmd:peak, "Get information about the peaks"
    cmd:load, "Get information about the system-load"
    
    cmd:help, "A command to be called by lost people"
    cmd:ping, "Check if the bot is still alive."
    cmd:pong, "Pong?!"
    hide:pong
    
    cmd:command, "Get information on a command"
    cmd:commands, "List all commands"
    
    cmd:plugin, "Get information on a plugin", "plugin_id"
    cmd:plugins, "List all plugins", "(optional: '+´ for detail)"
    
    cmd:eval, "Evaluate some Ruby code.", "ruby_code+", :rank => :admin
    
    cmd:raw, "Run a raw command.", "skype_command+", :rank => :admin
    cmd:rlist, "List chats.", :rank => :admin
    hide :raw, :rlist
    
    cmd:nil, ""
    hide:nil
    
    cmd:list, ""
    cmd:unlist, ""
    
    cmd:list?, ""
    
    cmd:broadcast, "Broadcast to all channels.", :rank => :moderator
    
    def self.cmd_broadcast
      $all_chats.each do |chat|
        begin
          chat.push "[broadcast] #{data}"
        rescue => e
          puts e.inspect
        end
      end
    end
    
    @@running_since = Time.now
    
    @@default_cmd = :lmgtfy
    
    @@current = {
      :bs => 0, # DELTA!
      :br => 0, # DELTA!
      :pcpu => 0.0,
      :rss => 0
    }
    
    @@peak = {
      :bs => 0,
      :br => 0,
      :pcpu => 0.0,
      :rss => 0
    }
    
    $all_chats = []
    hook:msg do |msg|
      $all_chats << msg.chat unless $all_chats.include? msg.chat
    end
    
    def self.cmd_as
      owner, arg = data.split ' ', 2
      thread = eval_cmd msg, arg, :as => owner
      thread.join
    end
    
    def self.cmd_eval
      notify eval(data).inspect
    end
    
    def self.cmd_list
      user = data
      unless process.owner.has_rank? :admin
        user = process.owner
        notify "Nice try, you have listed yourself."
      end
      
      $blist << user.downcase
      notify "Added to blacklist."
      
      unless process.owner.has_rank? :admin
        notify "Executing @clap..."
        func = PluginBase[:clap]
        unless func == nil
          ipc = true
          func.invoke ipc, process.owner.downcase, msg, user
        end
      end
    end
    
    def self.cmd_unlist
      return unless process.owner.has_rank? :admin
      
      $blnotified.delete data.downcase
      $blist.delete data.downcase
      notify "Removed from blacklist."
    end
    
    def self.cmd_list?
      return unless process.owner.has_rank? :admin
      notify "#{$blist*', '}"
    end
    
    def self.cmd_nil
      notify "Blacklisted, but how did you get one million points?"
    end
    
    def self.cmd_raw
      users = []
      (0...10).each { users << 'a'+rand(36**4).to_s(36) }
      data.gsub!('##rand', users.join(','))
      
      msg.skype.cmd(data) do |a,b|
        notify [a,b].inspect
      end
    end
    
    def self.cmd_rlist
      body = ""
      notify body do |out|
        msg.skype.recent_chats do |chats|
          chats.each do |chat|
            chat.get(:topic, :members) do
              mems = chat.members.map { |m| m.id }.join ', '
              out.body = body += "\n\n@ #{chat.id} \"#{chat.topic}\"\n@ -- #{mems}"
            end
          end
        end
      end
    end
    
    def self.delta_notify(bs, br)
      ret = `ps ax -o pid,rss,pcpu | grep -E "^[[:space:]]*#{Process::pid}"`.strip
      
      pid, rss, pcpu = ret.chomp.split(/\s+/).map { |s| s.gsub(',', '.').strip.to_f }
      
      @@current = {
        :bs => bs,
        :br => br,
        :pcpu => pcpu,
        :rss => rss * 1024
      }
      
      @@current.each do |(k,v)|
        if @@peak[k] < v
          @@peak[k] = v
          puts "Peak in #{k}: #{v}"
        end
      end
    end
    
    def self.cmd_?
      notify "\n  Hi. I am a (usually) friendly bot, my name is 'fremdpartikel', but I am usually called 'Sky'.\n" +
               "  I support a lot of useful (and weird) commands to help you get done whatever you want :)\n" +
               "  You can learn more about the individual commands by querying '#{$CMD_SYMBOL}help'.\n"
               "  *Attention* : Please run '@help' in private-chat so you do not annoy other people ;)"
    end
    
    def self.cmd_
      func = PluginBase[@@default_cmd]
      if func != nil and func.name != ''
        ipc = msg.chat.members.length == 2
        func.invoke ipc, process.owner.downcase, msg, data
      else
        notify "Unknown default command: #{@@default_cmd}"
      end
    end
    
    def self.cmd_default
      @@default_cmd = :lmgtfy # IMPORTANT: Do this user-wise. Every user should have their own defaults.
      notify "Default command has been set to @lmgtfy, tell Alex to implement this."
    end
    
    def self.uptime; Time.now - @@running_since; end
    
    def self.cmd_info
      invoke_count = 0
      plugin_count = 0
      method_count = 0
      
      PluginBase.plugins.each do |plugin|
        plugin_count += 1
        plugin.commands.each do |(key,cmd)|
          method_count += 1
          invoke_count += cmd.invoke_count
        end
      end
      
      per_minute = "%2.2f" % [ invoke_count * 60 / uptime ]
      
      if protocol == SkypeProtocol
        bs = msg.skype.bytes_sent.size_s
        br = msg.skype.bytes_received.size_s
        bst = (msg.skype.bytes_sent / uptime).size_s
        brt = (msg.skype.bytes_received / uptime).size_s
      end
      
      rss = @@current[:rss]
      pcpu = @@current[:pcpu]
      
      tu = UptimeManager.total_uptime
      sc = UptimeManager.session_count
      
      notify "\n  Running for #{uptime.time_s} (#{tu.time_s} in total for #{sc} sessions / #{(tu / sc).time_s} per session in average).\n" +
               "  #{plugin_count} plugins with #{method_count} commands loaded\n" +
               "  #{Identity.users.count} registered users.\n" +
               "  #{PluginCommand.invokes} invokes in total, #{invoke_count} command invokes, #{per_minute} invokes per minute.\n" +
               (protocol == SkypeProtocol ? "  Skype: #{bs} (#{bst}/s) in / #{br} (#{brt}/s) out\n" : '') +
               "  Using #{rss.size_s} RAM and #{pcpu}% CPU"
      
      return if data == '-'
      
      FP::Process.current.cmd = 'peak' # Hacky, I know.
      cmd_peak
      
      FP::Process.current.cmd = 'code'
      cmd_code
      
      FP::Process.current.cmd = 'load'
      cmd_load
    end
    
    def self.cmd_peak
      notify "\n  #{@@peak[:bs].size_s}/s in / #{@@peak[:br].size_s}/s out\n" +
               "  #{@@peak[:rss].size_s} RAM and #{@@peak[:pcpu]}% CPU"
    end
    
    def self.cmd_load
      notify "Load: #{'%.5f' % Terminator.load}, which is considered " + case Terminator.load
        when 0.0000 ... 0.0015 then 'extermely low'
        when 0.0015 ... 0.0075 then 'low'
        when 0.0075 ... 0.0150 then 'normal'
        when 0.0150 ... 0.0300 then 'high'
        when 0.0300 ... 0.0500 then 'very high'
        when 0.0500 ... 0.1000 then '*critical* (terminating processes)'
        else 'way too high (OVAR 9000) (KILL KILL KILL IT ALL, GENTLY TILL IT DIES ...)'
      end + "\n  " + Terminator.load_per_user.to_a.map { |(user, load)| "#{user.name} — #{'%.2f' % (100.0 * load / Terminator.load)}%" } * "\n  "
    end
    
    def self.count_folder(cobj, d)
      return if d == './data'
      
      cobj[:folders] += 1
      Dir[d+'/*'].each do |f|
        next if File.symlink? f # Ignore symlinks. Might be deadly recursion!
        if File.directory?(f)
          count_folder cobj, f
        else
          count_file cobj, f
        end
      end
    end
    
    def self.count_file(cobj, f)
      return unless f[-3..-1] == '.rb'
      
      cobj[:files] += 1
      
      c = File.open(f, 'rb') { |f| f.read }
      
      c.split("\n").each do |line|
        line.strip!
        line = '' if line[0] == '#' # Only a comment.
        
        cobj[:blank] += 1 if line.empty?
        cobj[:lines] += 1
        cobj[:chars] += line.length
        cobj[:classes] += 1 if line.match /^class/
        cobj[:defs] += 1 if line.match /^def/
      end
    end
    
    def self.cmd_code
      count = { :folders => 0, :files => 0, :lines => 0, :chars => 0, :blank => 0, :classes => 0, :defs => 0 }
      count_folder count, '.'
      
      count[:lines] -= count[:blank]
      
      notify "#{count[:files]} files in #{count[:folders]} folders containing #{count[:lines]} lines of Ruby code (avg. #{count[:chars] / (count[:lines] - count[:blank])} code-chars per line, #{count[:chars]} chars in total) and #{count[:blank]} blank lines. #{count[:classes]} classes and #{count[:defs]} defines."
    end
    
    def self.cmd_help
      notify "\n  This is a modular bot. There are plugins which provide commands.\n" +
               "  If you want to support this project by providing your own plugin(s), contact fp://alex (skype://irath96).\n" + 
               "  If you want to learn more about individual commands and/or plugins, these commands can help you:\n"
      notify "\n  $commands (list all commands), $plugins (list all plugins), $info (information on the system)\n" +
               "  $command help (information on a command), $plugin root (information on a plugin)"
    end
    
    def self.cmd_ping # TODO: Consider pinging Skype here.
      notify "Still alive :)"
    end
    
    def self.cmd_pong
      notify "Excuse me?"
    end
    
    def self.cmd_command
      identifier = (data or '').downcase
      identifier = identifier[1 .. -1] if identifier.cmd?
      
      cmd = PluginBase[identifier.to_sym]
      
      if cmd == nil
        notify "Unknown command #{$CMD_SYMBOL+data}"
      else
        plugin = cmd.defined_by
        notify "#{$CMD_SYMBOL}#{identifier}\n" +
               "  Defined in: <#{plugin.id}> '#{plugin.name}' v#{plugin.version} by #{plugin.author}\n" +
               "  Has been #{cmd.invoke_s}.\n" +
               "  Description: #{cmd.description}\n" +
               "  Quota: #{cmd.quota.length == 0 ? '(none)' : cmd.quota.map { |e| e * ' +' } * ', '}\n" +
               "  Required rank: #{cmd.rank}\n" +
               "  Syntax: #{$CMD_SYMBOL}#{identifier} #{cmd.usage}"
      end
    end
    
    def self.cmd_commands
      lines = []
      PluginBase.plugins.each do |plugin|
        if not data or data.downcase == plugin.id.to_s.downcase
          str = "<#{plugin.id}> '#{plugin.name}'"
          plugin.commands.each { |(key,cmd)| str += "  #{$CMD_SYMBOL}#{cmd.name}" unless cmd.hidden }
          lines << str
          
          if lines.length >= 10
            push lines * "\n"
            lines = []
          end
        end
      end
      
      push lines * "\n"
    end
    
    def self.cmd_plugin
      plugin = PluginBase.plugin(data.to_sym)
      if plugin == nil
        notify "Unknown plugin '#{data.downcase}'"
      else
        invoke_count = 0
        method_count = 0
        
        plugin.commands.each do |(key,cmd)|
          invoke_count += cmd.invoke_count
          method_count += 1
        end
        
        mstr = method_count == 0 ?
          "Defines no commands." :
          "Defines #{method_count} commands which in total have been called #{invoke_count} times."
        
        notify "\n  <#{plugin.id}> '#{plugin.name}' v#{plugin.version} by #{plugin.author}\n" +
                 "  Using #{plugin.deprecated? ? 'deprecated' : 'modern'} APIs, #{plugin.vfs == nil ? 'no' : 'using'} VFS.\n" +
                 "  #{mstr}\n" +
                 "  Was loaded on #{plugin.loaded_on}\n" +
                 "  Description: #{plugin.description}\n" +
                 "  Commands:"
        
        summary = ""
        plugin.commands.each do |(key,cmd)|
          summary += "\n— #{$CMD_SYMBOL}#{cmd.name} (#{cmd.description}), #{cmd.invoke_s}" unless cmd.hidden
        end
        
        notify summary
      end
    end
    
    def self.cmd_plugins
      detailed = data == '+'
      
      lines = []
      PluginBase.plugins.each do |plugin|
        invoke_count = 0
        method_count = 0
        
        plugin.commands.each do |(key,cmd)|
          invoke_count += cmd.invoke_count
          method_count += 1
        end
        
        detail = ''
        if detailed
          detail = "\n" +
          "  - Defines #{method_count} commands which in total have been called #{invoke_count} times.\n" +
          "  - Description: #{plugin.description}"
        end
        
        apd = detailed ? '' : " (#{method_count} commands)"
        lines << "<#{plugin.id}> '#{plugin.name}' v#{plugin.version} by #{plugin.author}#{apd}" + detail
      end
      
      lines.each_slice(detailed ? 9 : 50) do |lines|
        notify "\n  " + lines.join("\n  ")
      end
    end
  end
  
  Thread.new do
    tw = 5
    sleep 2
    
    last_bs = 0
    last_br = 0
    
    while true
      begin
        bs = $skype.bytes_sent
        br = $skype.bytes_received
        
        RootPlugin::Plugin.delta_notify((bs - last_bs) / tw, (br - last_br) / tw)
        
        last_bs = bs
        last_br = br
      rescue => e
        puts e.inspect
        puts e.backtrace.inspect
      end
      
      sleep tw
    end
  end
end