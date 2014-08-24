require 'net/http'
require 'cgi'

module CountdownPlugin
  class FunLock
    attr_accessor :locked
    def initialize; @locked = true; end
    def unlock; @locked = false; end
  end
  
  class Plugin < PluginBase
    init_v2 :countdown
    
    meta :name => "Countdown Plugin",
         :author => "Alexander Rath",
         :version => 0.5,
         :description => "Timeout stuff. @countdown 10s @kill Paul"
    
    cmd :countdown, "Create a countdown", "@countdown 100"
    cmd :toco, "Toggle countdowns on/off.", "@toco", :rank => :admin
    
    @@disable = false
    
    def self.cmd_countdown
      t, d = (data or '10 BOOM').split(' ', 2)
      t = t.to_i
      t = 10 if t < 0
      
      dec = t / 250.0
      dec = 1 if dec < 1
      
      lock = FunLock.new
  
      notify "(loading)" do |m|
        create_thread do
          while true
            m.body = "#{prefix}#{t.time_s}"
            break if t <= 0
            
            t -= dec
            sleep dec
          end
          
          lock.unlock
        end
      end
      
      sleep 0.1 while lock.locked
      
      if d[0...$CMD_SYMBOL.length] == $CMD_SYMBOL
        cmd, data = d.split(' ', 2)
        func = PluginBase[cmd[1 .. -1].downcase.to_sym]
        
        if func == nil
          notify "Unknown command."
        else
          ipc = msg.chat.members.length == 2
          thread = eval_cmd msg, d # func.invoke ipc, msg.from_handle.downcase, msg, data
          thread.join unless thread == nil
        end
      else
        notify "#{d}"
      end
    end
    
    def self.cmd_toco
      @@disable = !@@disable
      notify @@disable ? 'Countdowns disabled!' : 'Countdowns enabled!'
    end
    
    def self.cmd_countdown_non_thread
      t, d = (data or '10 BOOM').split(' ', 2)
      t = t.to_i
      t = 10 if t < 0
      
      dec = t / 250.0
      dec = 1 if dec < 1
      
      notify "(loading)" do |m|
        while true
          return if @@disable
          m.body = "#{prefix}#{t.time_s}"
          break if t <= 0
          
          t -= dec
          sleep dec
        end
        
        if d[0...$CMD_SYMBOL.length] == $CMD_SYMBOL
          cmd, data = d.split(' ', 2)
          func = PluginBase[cmd[1 .. -1].downcase.to_sym]
          
          if func == nil
            notify "Unknown command."
          else
            ipc = msg.chat.members.length == 2
            #func.invoke ipc, msg.from_handle.downcase, msg, data
            eval_cmd msg, d
          end
        else
          notify "Done!"
        end
      end
    end
  end
end