require './protocols/omegle/OmegleClient.rb'

module PipePlugin
  class Pipe < PluginBase
    init_v2 :pipe
    
    meta :name => "Pipe Plugin",
         :author => "Alexander Rath",
         :version => 0.0,
         :description => "A bridge to pipe chats (Omegle, Xat, Skype, IRC, etc) to other chats."
    
    cmd :beta, "Beta.", "@beta music cake"
    cmd :push, "Push.", "@push a7 Hello"
    
    def self.cmd_beta
      o = OmegleClient.new (data or '').split(' ')
      o.start_update_thread
      
      @om = o
      
      o.on(:status) do |stat|
        msg.chat.push "@beta :-  Status: #{stat.inspect}"
      end
      
      o.on(:likes) do |l|
        msg.chat.push "@beta :-  Common Likes: #{l.inspect}"
      end
      
      o.on(:message) do |ms|
        msg.chat.push "@beta :-  -> #{ms}"
      end
      
      o.on(:disconnect) do
        msg.chat.push "@beta :-  Disconnected."
      end
    end
    
    def self.cmd_push
      @om.push data
    end
  end
end