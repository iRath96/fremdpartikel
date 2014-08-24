require 'nokogiri'
require 'net/http'
require 'cgi'

module YoutubePlugin
  class Plugin < PluginBase
    init_v2 :youtube
    
    meta :name => "Youtube Plugin",
         :author => "Alexander Rath",
         :version => 0.5,
         :description => "A bridge to Youtube."
    
    cmd :'yt-search', "Search for videos on YT.", "@yt-search Fluffy Kitten"
    
    def self.cmd_yt_search
      uri = URI.parse('http://www.youtube.com/results?search_query=' + CGI.escape(data))
      html = Net::HTTP.get uri
      doc = Nokogiri::HTML.parse html
      
      doc.css('h3')[2..-1].each do |title|
        e = title.parent.parent
        
        link = (uri + e.css('a')[0].attr(:href)).to_s rescue "/"
        time = e.css('.video-time').text rescue "00:00"
        badge = e.css('.yt-badge').text rescue ""
        meta = e.css('li').collect { |i| i.text.strip } * ' | ' rescue "" # LAZY!
        desc = e.css('div div')[1].text.strip rescue "(no description)"
        
        notify "#{link}\n  \"#{title.text}\" (#{time}) #{badge}\n  #{meta}\n  #{desc}"
      end
    end
  end
end