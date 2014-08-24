module TestPlugin
  class Plugin < PluginBase
    init_v2 :test
    init_vfs :read => :public, :write => :public
    
    meta :name => "TestPlugin",
         :author => "Alexander Rath",
         :version => 0.0,
         :description => "Just testing stuff with this."
    
    cmd:test, "Test", :rank => :guest
    cmd:test2, "Test 2", :rank => :guest
    
    def self.cmd_test
      notify "You are #{msg.user.uid}"
      sleep 10
      notify "Slept."
    end
    
    def self.cmd_test2
      $the_chat = msg.chat
      if protocol.shorten?
        notify "You are on a protocol that wants short messages."
      else
        notify "You are on a protocol that does not need short messages."
      end
    end
  end
end