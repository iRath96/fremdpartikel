require 'net/http'
require 'cgi'

module WikipediaPlugin
  class Plugin < PluginBase
    init_v2 :wikipedia
    
    meta :name => "Wikipedia Plugin",
         :author => "Alexander Rath",
         :version => 0.0,
         :description => "A bridge to Wikipedia."
  end
end