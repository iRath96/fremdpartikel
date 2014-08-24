# encoding=utf-8

module LegacyPlugin
  class Plugin < PluginBase
    init_v2 :legacy
    
    meta :name => "Legacy Plugin",
         :author => "Alexander Rath",
         :version => 0.5,
         :description => "Defines important commands like @dance, @kill, @meow and @buy-food"
    
    cmd:rob, "Rob somebody / something", "@rob bank"
    cmd:dance, "Dance, gotta be okay!"
    cmd:eat, "Eat something / somebody", "@eat cake"
    cmd:drink, "Drink something", "@drink cake"
    cmd:meow, "Meow :3"
    cmd:rawr, "Rawr >:3"
    cmd:die, "Tell the bot to die"
    cmd:revive, "Revive from the dead"
    cmd:damnit, "Swear"
    cmd:escape, "Escape"
    cmd:'buy-food', "Buy some food for Alex.", "@buy-food ham"
    cmd:kill, "Kill somebody"
    cmd:fry, "Fry somebody"
    cmd:thanks, "Thank the awesome bot.", "@thanks a lot"
    cmd:clap, "Congratulate the user."
    cmd:party, "Time to party!"
    cmd:'rick-roll', "Rick roll!"
    cmd:say, "Say something.", "@say Hello"
    cmd:me, "Say something in EMOTED mode", "@me is a chimp"
    cmd:sudo, ""
    cmd:hammertime!, ""
    cmd:please, "Beg for MERCY"
    cmd:flash, "Flash a text."
    
    def self.cmd_flash
      (1...d.length).each do |i|
        msg.body = '#' * i
        sleep 0.5
      end
      
      (1..d.length).each do |j|
        i = d.length - j
        msg.body = '#' * i + d[i] + '#' * (j - 1)
        sleep 0.5
      end
      
      (1..d.length).each do |j|
        i = d.length - j
        msg.body = '#' * i + d[i..-1]
        sleep 0.5
      end
    end
    
    hide :sudo
    cmd:†, "Test"
    
    hide :*
    
    def self.cmd_†; push "May he/she rest in peace."; end
    def self.cmd_please; push "Okay, but just because it's you."; end
    
    def self.cmd_hammertime!; push "U CAN'T TOUCH THIS!"; end
    def self.cmd_sudo; push "-bash: kill: James: arguments must be process or job IDs"; end
    def self.cmd_rob; push "** robs #{d}"; sleep 0.7; m.chat.push "** shot down by police."; end
    def self.cmd_dance; push "(dance)"; end
    def self.cmd_eat; push "I am not hungry, thanks."; end
    def self.cmd_drink; push "I am not thirsty, thanks."; end
    def self.cmd_meow; push "Fluffy kittens!"; end
    def self.cmd_rawr; push "Yay, fluffy kittens!"; end
    def self.cmd_die; push "Are you expecting me to talk?"; end
    def self.cmd_revive; push "I wasn't dead, you know."; end
    def self.cmd_damnit; push "Mh, that sucks, I know."; end
    def self.cmd_escape; push "Bye!"; end
    def self.cmd_buy_food; push "I ain't got no money .__.\""; end
    def self.cmd_kill; push "Sorry, that's impolite."; end
    def self.cmd_fry
      push "** fries #{d}"; sleep 0.65; push "** sells fried #{d} on ebay"; sleep 0.45
      push "???"; sleep 1.1; push "** PROFIT!"
    end
    def self.cmd_thanks; push "No problem. Glad I could help!"; end # TODO: A thanks-list.
    def self.cmd_clap; push "(clap)"; sleep 1.3; push "You did just great on that!"; sleep 0.5; push "Wonderful, just excellent."; sleep 0.9; push "It's simply amazing!"; end
    def self.cmd_party; push "(party)"; sleep 1.3; push "Yay, lets party."; sleep 0.5; push "Aww man, no apple juice."; sleep 0.9; push "This party is over."; end
    def self.cmd_rick_roll
      push "Never gonna give you up,"; sleep 1.3
      push "Never gonna let you down"; sleep 1.2
      push "Never gonna run around and desert you"; sleep 1.1
      push "Never gonna make you cry,"; sleep 1.0
      push "Never gonna say goodbye"; sleep 0.9
      push "Never gonna tell a lie and hurt you"#; sleep 0.8
    end
    
    api :say do |d|
      d = d.to_s
      
      d.gsub! "\xC2\xA0".force_encoding("ascii-8bit"), " " # UTF-8 space to normal space converstion
      d.strip!
      
      d = ":#{d}" if d[0] == ?/
      push d
    end
    
    api :me do |d|
      push "/me #{d}"
    end
  end
end