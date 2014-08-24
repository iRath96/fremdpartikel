module TwitterPlugin
  class Plugin < PluginBase
    init_v2 :twitter
    
    meta :name => "Twitter Plugin",
         :author => "Alexander Rath",
         :version => 0.0,
         :description => "Deals with interacting with Twitter (posting tweets, following people, reading timelines, etc.)"
    
    cmd:tweet, "Post a tweet", "@tweet Hm... @ruby can't compare time with 5. #fml"
    cmd:'twitter-user', "Get information on a user", "@twitter-user irath96"
    cmd:timeline, "Show the timeline of a user", "@timeline irath96"
    
    def self.cmd_tweet
      notify "Not yet implemented."
    end
  end
end