require 'net/http'
require 'cgi'
require 'htmlentities' # better than CGI.unescapeHTML

require 'tesseract'

puts "TODO: Catch 'require'-exceptions and disable optional features."
puts "TODO: Convert google.com etc into http://links/" # Should be disableable (is that even a word?), and should not happen for commands (!)
module WebnetPlugin
  class Plugin < PluginBase
    init_v2 :webnet
    
    meta :name => "Webnet Plugin",
         :author => "Alexander Rath",
         :version => 0.3,
         :description => "Resolves links that are sent in chat and displays their <title>."
    
  ##cmd :resolve, "Figure out what's behind a link.", "@resolve http://google.com/"
    cmd :lmgtfy, "Let me google that for you.", "@lmgtfy Is Elvis dead?"
    @@last_lmgtfy = 'Is Elvis dead?'
    
    def self.cmd_resolve(msg, link, level=3)
      return if msg.body[0 ... 12] == '@webnet :-  '
      
      if level == 0
        msg.chat.push "@webnet :-  #{link}, too many redirects."
        return
      end
      
      if link.match(/\.(png|jpg|jpeg)$/i)
        msg.chat.push "@webnet :-  How lovely, I should use tesseract."
        engine = Tesseract::Engine.new
        
        temp = open(link)
        msg.chat.push "@webnet :-  #{link}\n" + engine.text_for(temp.path)
        return
      end
      
      uri = URI.parse(link)
      resp = Net::HTTP.get_response uri
      case resp.code.to_i
        when 200
          title = resp.body.scan /<\s*title[^>]*>(.*?)<\s*\/title\s*>/i
          title = title.shift.to_a.shift.to_s
          
          msg.chat.push "@webnet :-  #{link} - \"#{HTMLEntities.new.decode title}\""
        when 301, 302
          loc = (uri + resp['location']).to_s
          msg.chat.push "@webnet :-  #{link} links to #{loc} (relative:#{resp['location']})!"
          cmd_resolve msg, loc, level - 1
        when 404
          msg.chat.push "@webnet :-  #{link} cannot be found!"
        else
          msg.chat.push "@webnet :-  #{link} #{resp.code} ?!"
      end
    end
    
    def self.cmd_lmgtfy
      data = @@last_lmgtfy if data == nil
      @@last_lmgtfy = data
      
      notify "http://lmgtfy.com/?q=" + URI.escape(data)
    end
    
    hook:msg do |msg|
      pt = $root_thread
      #msg.get_cached(:body, :chatname, :sender_handle) do |body, cname, handle|
        body = msg.body
        body.scan(/(http[s]?:\/\/[^ ]+)/).each do |(link)|
          Thread.new do # And another bug gone, another bug gone - another bug bites the dust!
            process = FP::Process.new msg.chat, pt, HashResponder.new(:uid => 'plugin://webnet/'), 'resolve', link, { 'handle' => msg.user, 'link' => link }
            cmd_resolve msg, link
            process.kill
          end
        end
      #end
    end
  end
end