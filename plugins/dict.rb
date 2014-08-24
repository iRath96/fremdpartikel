require 'nokogiri'
require 'net/http'
require 'cgi'

module DictPlugin
  class Plugin < PluginBase
    init_v2 :dict
    
    meta :name => "Dict Plugin",
         :author => "Alexander Rath",
         :version => 0.3,
         :description => "A bridge to dict.cc"
    
    cmd :dict, "Translate a word", "lang_code query+"
    
    def self.cmd_dict
      lang, *word = data.split(' ')
      word *= ' '
      
      sdm = lang[0...4].downcase # Check a-z?
      
      html = Net::HTTP.get URI.parse('http://' + sdm + '.dict.cc/?s=' + CGI.escape(word))
      doc = Nokogiri::HTML.parse html
      
      if doc.css('td.bluebar [align="right"]').text == 'No entries found!'
        # Suggestions?
        
        tops = doc.css('table td.td2')
        sugs = doc.css('td.td3nl')
        
        (0..1).each { |i| msg.chat.push "@dict #{data} :-  #{tops[i].text}: " + sugs[i].css('a').collect { |a| a.text } * ', ' }
      else
        a, b = doc.css('td.td2 b')
        msg.chat.push "@dict #{data} :-  #{a.text.strip} <--> #{b.text.strip}"
        
        header = 'Direct translation'
        out = []
        
        trs = doc.css('td.td7nl')[0].parent.parent.css('tr') # doc.css('td.td7nl').collect { |i| i.parent }.uniq
        
        first = 0
        trs.each_with_index do |tr,i|
          if tr.attr :id
            first = i
            break
          end
        end
        
        trs[first..-1].each do |tr|
          unless tr.attr :id
            header = tr.text
            
            if out.length
              msg.chat.push(out*"\n")
              out = []
            end
            
            msg.chat.push "@dict #{data} :-  #{header}"
          else
            a, b = tr.css('td.td7nl')
            
            aa = a.css('a').collect { |i| i.text } * ' '
            ab = b.css('a').collect { |i| i.text } * ' '
            
            va = a.css('var').collect { |i| i.text } * ' '
            vb = b.css('var').collect { |i| i.text } * ' '
            
            out << "* #{aa} #{va} <=> #{ab} #{vb}"
          end
        end
        
        if out.length
          msg.chat.push(out*"\n")
          out = []
        end
      end
    end
  end
end