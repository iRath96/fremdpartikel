module LyricsPlugin
  class Plugin < PluginBase
    init_v2 :lyrics
    
    meta :name => "Lyrics Plugin",
         :author => "Alexander Rath",
         :version => 0.2,
         :description => "Play the Lyrics Game"
    
    cmd :lyrics, "Start a new question."
    cmd :solve, "Solve"
    
    @@answer = nil
    
    def self.cmd_lyrics
      uri = URI.parse 'http://www.lyrics.com/'
      main = Nokogiri::HTML.parse open(uri)
      (1..50).each do
        begin
          title, band = main.css('div#topsongs td').to_a.sample.css('a')
          next if title.text.strip == ''
          
          @@answer = title.text.strip + ' - ' + band.text.strip
          
          lyrics = Nokogiri::HTML.parse open(uri + title.attr(:href))
          lyrics = lyrics.css('div#lyrics').text
          
          lines = lyrics.split("\n").map(&:strip).find_all { |a| a.length > 4 }
          line = lines.sample
          
          next if line == nil
          
          notify "#{line}"
          
          break
        rescue => e
        end
      end
    end
    
    def self.cmd_solve
      notify "#{@@answer}"
    end
  end
end