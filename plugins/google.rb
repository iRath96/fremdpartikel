require 'net/http'
require 'cgi'

module GooglePlugin
  class GooglePlugin < PluginBase
    init_v2 :google
    
    meta :name => "Google Plugin",
         :author => "Alexander Rath",
         :version => 0.0,
         :description => "A bridge to Google."
  end
end