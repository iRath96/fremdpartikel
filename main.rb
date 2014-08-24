puts "TODO: priority for processes"
puts "TODO: Network access in script.rb"
puts "TODO: A pin and a todo-command. With VFS :)"
puts "TODO: New invoke-system!" # @countdown [[ @test ;; @meow ;; @whatever ^[[ @ret 2 ]] ]]

$CMD_SYMBOL = "$"

#
# TODO: There is a lot to do. Check the files and you will see!
# ATTENTION: There is a design-failure. In SkypePlugin::Plugin.avatar for instance!
#            Whenever a callback wants to invoke 'notify´ it will fail because the process does not wait for callbacks to finish!!!
#

#
# Checklist (to support other protocols):
# - A proper Console-class would be nice (should be able to pipe to chats, etc)
# x User identification / Access control lists / permissions
# x A clean interface for protocols, chats and messages (process.owner should be an User-Object)
# x Remove the FP-prefix from some classes. Maybe put them in a FP module?
# - Trusted users for Terminator-killing
# x Persistant Objects
# - A callback-object, that allows processes to have pending callbacks (see "ATTENTION"), so they can continue working until the work is over. (see FP:Process todo)
#   - Keep in mind, though, that 'OUR WORK IS NEVER OVER.´
# x More todos!
# - Dynamic loadable plugins
# - Loadable protocols (connecting to other IRC servers, for instance) - also dynamically loadable?
# - Implement 'poll´ for Users and Chats!
# - SSH and Web-SSH
# - QuotaError for systems (in the API there has to be a 'protocol´ / 'connection´ method)
# x Limit amount of messages sent on IRC. Seriously.
#   x There should be parameters that can be passed to commands based on the protocol used so they know if they need shorter output.
# - IRCPlugin that will allow cool DCC stuff
# - FP::Process spawning threads? Also, callback in threads assigned to processes!
# - For IRC consider linebreaks as new messages in the QuotaManagement
# - Different commands for different ranks (overloading)
# - Better formatting using fontface checking (maybe also let Users set their own font in their settings)
# x Add settings for users
# - Allow "\" at the end of messages for multiline messages in chats that do not support it?
# - Allow login from Telnet
# - Services (which will replace 'hook´s)
# - Allow cronjobs for RubyPlugin
#

require './classes/common.rb'

require './bootstrap.rb'
ProtocolManager.run

puts "ran"

require './plugins/bootstrap.rb'

puts "bootstrap"

require './fremdpartikel.rb'

puts "ready"

while true
  begin
    puts "\033[32m@ mainthread\033[0m"
    sleep 300
  rescue => e
    puts "  @ error #{e.inspect}"
  end
end