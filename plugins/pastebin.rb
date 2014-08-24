require 'net/http'
require 'cgi'

module PastebinPlugin
  class Plugin < PluginBase
    init_v2 :pastebin
    
    meta :name => "Pastebin Plugin",
         :author => "Alexander Rath",
         :version => 0.0,
         :description => "A bridge to Pastebin."
  end
end