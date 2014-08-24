require "./classes/dispatcher.rb"

require_relative "skype-object.rb"
require_relative "skype-profile.rb"

Dir[File.dirname(__FILE__) + '/*.rb'].each { |f| require_relative f }

#
# Message handler.
#

require "mysql"

$mysql = Mysql.connect "127.0.0.1", "root", "", "skype"
$VERSION = 1

class SkypeProtocol < Protocol
  init :skype
  
  def self.shorten?; false; end
  def self.name; "Skype"; end
  
  def self.run(**params)
    SkypeUser.on(:change) do |user, key, before, after|
      values  = "'" + $mysql.escape_string(user.id.to_s) + "', "
      values += "'" + $mysql.escape_string(key.to_s) + "', "
      values += "'" + $mysql.escape_string(after.to_s) + "', "
      values += Time.now.to_i.to_s + ', '
      values += $VERSION.to_s
      
      $mysql.query "INSERT INTO users (`handle`, `key`, `value`, `date_set`, `version`) VALUES (#{values})"
    end
    
    $skype = PluginBase.Skype = Skype.new ARGV[0].to_i
    $skype.on(:message_status) do |msg, status|
      if msg.is_new? && !msg.is_local?
        msg.get_cached(:body, :chatname, :sender_handle, :type, :timestamp) do
          msg.chat.get_cached(:members) do
            values  = msg.id.to_i.to_s + ', '
            values += '"' + $mysql.escape_string(msg.body) + '", '
            values += '"' + $mysql.escape_string(msg.type.to_s.upcase) + '", '
            values += '"' + $mysql.escape_string(msg.chatname) + '", '
            values += '"' + $mysql.escape_string(msg.from_handle) + '", '
            values += msg.timestamp.to_i.to_s
            
            begin
              $mysql.query "INSERT INTO msgs (`id`, `body`, `type`, `chatname`, `from_handle`, `timestamp`) VALUES (#{values})"
            rescue => e
              puts "MySQL query failed:"
              puts e.inspect
            end
            
            register_message msg, SkypeProtocol
          end # msg.chat.get_cached
        end # msg.get_cached
      end # if
    end # $skype.on
  end
end