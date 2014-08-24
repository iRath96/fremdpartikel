module WebcomicPlugin
  class Plugin < PluginBase
    init_v2 :webcomic
   
    meta :name => "Cyanide & Happiness Plugin",
         :author => "Jamie W. & Alexander Rath",
         :version => 0.1,
         :description => "Get a random comic!"
   
    cmd:webcomic, "Get a random comic!"
    cmd:xkcd, "Get a random xkcd-comic!"
   
    def self.cmd_webcomic
      first = 15
      latest = DateTime.now.mjd - DateTime.parse("2005-01-26").mjd + 154 - first # account for extras but subtract first
      notify "http://www.explosm.net/comics/#{rand(latest) + first}/"
    end
    
    def self.cmd_xkcd
      max_id = Time.now.to_i / (48 * 3600) - 6724
      id = rand(max_id + 1)
      notify "http://xkcd.com/#{id}"
    end
  end
end