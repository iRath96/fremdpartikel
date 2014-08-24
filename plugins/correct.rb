#require 'raspell'
module CorrectPlugin
  class Plugin < PluginBase
    init_v2 :correct
    
    meta :name => "Correction Plugin",
         :author => "Alexander Rath",
         :version => 0.6,
         :description => "Corrects people when they say 'Mac OS X' et cetera."
    
    @@okay = {}
    @@enabled = false
    
    cmd :learn, "Learn a word", "word"
    cmd :aspell, "Get suggestions for a misspelled word", "word"
    cmd :sisable, "Disable the spell-checker"
    cmd :senable, "Enable the spell-checker"
    
    def self.cmd_sisable(msg, data); @@enabled = false; end
    def self.cmd_senable(msg, data); @@enabled =  true; end
    
    def self.cmd_learn
      data.split(' ').each do |word|
        word = $mysql.escape_string(word.downcase)
        
        val  = '"' + word + '",'
        val += '"' + $mysql.escape_string(msg.from_handle) + '",'
        val += Time.now.to_i.to_s
        
        $mysql.query "INSERT INTO words (`word`, `handle`, `time`) VALUES (#{val})"
      end
      reload_words
      
      notify "Done!"
    end
    
    def self.reload_words
      q = $mysql.query "SELECT word FROM words"
      @@okay = {}; while w = q.fetch_hash; @@okay[w['word']] = true; end
      q.free
    end
    
    def self.init_aspell
      @@speller = Aspell.new("en_US")
      @@speller.suggestion_mode = Aspell::NORMAL
    end
    
    def self.cmd_aspell(msg, data)
      notify @@speller.suggest(data).map { |w| "\"#{w}\"" }.slice(0,10).join(', ')
    end
    
    hook:msg do |msg|
      #msg.get_cached(:body, :chatname, :sender_handle) do |body, cname, handle|
        body = msg.body
        
        next if body[0] == ?$
        next unless @@enabled
        
        body.gsub! /(http|ftp)\S+/, ''
        body = " #{body} "
        
        msg.chat.push "It's called 'OS X'" if body.match /Mac OS X/i
        msg.chat.push "Do you mean 'MAC' or 'Mac'?" if body.match /mac/
        msg.chat.push "Write 'I' instead of 'i'." if body.match /\si\s/
        
        if body.match /\salex\s/ or body.match /\spaul\s/ or body.match /\slorenzo\s/ or body.match /\sjames\s/
          msg.chat.push "Names are written uppercase."
        end
        
        if body.match /(d|D) Touch/
          msg.chat.push "The 'Touch' needs to be written lowercase."
        end
        
        if body.match /\sI(rath|pod|phone)|i(rath|pod|phone)|I(Rath|Pod|Phone)\s/
          msg.chat.push "Write the 'i' lowercase and the rest in camel-case."
        end
        
        wrong = []
        body.gsub(/[^\/@.:"'a-z][\w\']+[^.a-z]/i) do |word|
          word = word[1 ... -1]
          
          mx = 0
          mi = 1
          ml = "\x01"
          
          cs = word.downcase.chars.to_a
          cs.each do |c|
            if c == ml
              mi += 1
            else
              mi = 1
            end
            
            mx = mi if mi > mx
          end
          
          if mx < 3
            cs = cs.uniq.length # How many unique characters?
            if !@@okay[word.downcase] and !word.match(/[0-9]/) and cs > 2 and !@@speller.check(word) 
              wrong << word
              
              #msg.chat.push "@correct :-  Unknown \"#{word}\", did you mean " +
                #@@speller.suggest(word).map { |w| "\"#{w}\"" }.slice(0,10).join(', ')
            end
          end
        end
        
        msg.chat.push "@correct :-  Mistakes found: \"" + wrong.uniq.join('", "') + "\"" if wrong.length > 0
      end
    #end
  end
  
  Thread.new do
    sleep 2
    
    CorrectPlugin::Plugin.init_aspell
    CorrectPlugin::Plugin.reload_words
  end
end