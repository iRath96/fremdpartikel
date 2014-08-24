module FamePlugin
  class Plugin < PluginBase
    init_v2 :fame
    init_vfs :read => :public
    
    meta :name => "Hall of Fame",
         :author => "Alexander Rath",
         :version => 0.2,
         :description => "Who hacked Sky?"
    
    cmd:fame, "Add somebody to the fame list.", "@fame"
    cmd:fame?, "List the fame people.", "@fame?"
    
    def self.cmd_fame
      return false unless process.owner == 'irath96'
      vfs.root.mkfile 'list.txt', '', false
      vfs.root['list.txt'].append "#{Time.now} — #{data}\n"
      vfs.save
    end
    
    def self.cmd_fame?
      notify("\n  " + vfs.read('/list.txt').gsub("\n", "  \n"))
    end
  end
end