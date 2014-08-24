require 'net/http'
require 'cgi'

module MemoPlugin
  class Plugin < PluginBase
    init_v2 :memo
    
    meta :name => "Memo Plugin",
         :author => "Alexander Rath",
         :version => 0.0,
         :description => "Send messages to a user (immediately or after a certain time)"
  end
end