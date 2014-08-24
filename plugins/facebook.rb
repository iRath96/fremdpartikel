require 'net/http'
require 'cgi'

module FacebookPlugin
  class Plugin < PluginBase
    init_v2 :facebook
    
    meta :name => "Facebook Plugin",
         :author => "Alexander Rath",
         :version => 0.0,
         :description => "A bridge to fremdpartikels Facebook."
  end
end