module BotCorretPlugin
  class Plugin < PluginBase
    init_v2 :bot
    
    meta :name => "Bot Correct Plugin",
         :author => "Logan Viglienzoni",
         :version => 1.0,
         :description => "Corrects you by saying who he really is.."
    
    cmd:'bot', "Corrects Bot to Human.", "@bot"
    
    def self.cmd_bot
      notify "I am actually a human: #{data}"
    end
  end
end