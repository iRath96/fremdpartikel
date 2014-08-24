module FactPlugin
  $facts = File.open("./data/fact-plugin/facts").read.split "\x00" # Closing the file would be nice.
  $chuck = File.open("./data/fact-plugin/chuck").read.split "\x00" # See above :)
  $naked = File.open("./data/fact-plugin/naked").read.split "\x00" # See above :)
  $jokes = File.open("./data/fact-plugin/jokes").read.split "\x00" # See above :)
  
  class Plugin < PluginBase
    init_v2 :fact
    
    meta :name => "Fact Plugin",
         :author => "Alexander Rath",
         :version => 1.2,
         :description => "Can tell you interesting facts."
    
    cmd:joke, "Tells a classic joke.", "(option: id, otherwise random)"
    cmd:fact, "Let it tell you a fact.", "(option: id, otherwise random)"
    cmd:naked, "Let it tell you a quote from 'The Naked Gun'.", "(option: id, otherwise random)"
    cmd:chuck, "Let it tell you a fact about Chuck Norris.", "(option: id, otherwise random)"
    hide:chuck
    
    def self.cmd_joke
      id = data == nil ? rand($jokes.length) : data.to_i - 1
      question, answer = $jokes[id].split "?"
      notify "#{id + 1} - #{question}?"
      sleep 3
      notify "#{id + 1} - #{answer}"
    end
    
    def self.cmd_fact
      id = data == nil ? rand($facts.length) : data.to_i - 1
      notify "#{id + 1} - #{$facts[id]}"
    end
    
    def self.cmd_chuck(msg, data)
      id = data == nil ? rand($chuck.length) : data.to_i - 1
      notify "#{id + 1} - #{$chuck[id]}"
    end
    
    def self.cmd_naked(msg, data)
      id = data == nil ? rand($naked.length) : data.to_i - 1
      notify "#{id + 1} - #{$naked[id]}"
    end
  end
  
  Thread.new do
    sleep 1 while $skype == nil
    while true
      begin
        id = rand (a = rand(3) == 0 ? $facts : (rand(2) == 0 ? $naked : $chuck)).length
        $skype.set :mood, "Fact #{id+1}: #{a[id]}"
      rescue => e; puts "Cannot update mood in <fact.rb>: " + e.inspect; end
      sleep 30
    end
  end
end