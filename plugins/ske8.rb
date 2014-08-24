require 'active_record'
require 'logger'

module SKE8Plugin
  class Plugin < PluginBase
    init_v2 :ske8
    init_vfs :read => :public
    
    meta :name => "SKE8 Plugin",
         :author => "Alexander Rath",
         :version => 0.9,
         :description => "Helps managing Skype file-transfers."
  end
end

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection(
  :adapter  => 'mysql',
  :database => 'ske8',
  :username => 'root',
  :host     => 'localhost'
)

class Drop < ActiveRecord::Base; end

def process_drop(transfer)
  transfer.get(:filename, :filepath, :partner_handle, :partner_dispname, :filesize, :starttime) do
              | filename,  filepath,  partner_handle,  partner_dispname,  filesize,  starttime|
    
    vfs = SKE8Plugin::Plugin.vfs
    content = File.open(filepath, 'rb') { |f| f.read }
    vfs_filename = filepath.split('/').pop
    
    vfs.root.mkfile vfs_filename, content
    vfs.save
    
    #
    # Put the drop in the database.
    #
    
    drop = Drop.new
    drop.transfer_id = transfer.id
    drop.from_handle = partner_handle
    drop.from_disp = partner_dispname
    drop.filename = filename
    drop.filepath = filepath
    drop.timestamp = Time.now.to_i
    drop.starttime = starttime
    drop.filesize = filesize
    drop.hit_count = 0
    drop.save
    
    $rechats.each do |chat|
      chat.push "@ske8 #{drop.id} :-  #{filename} by #{partner_dispname} (#{partner_handle})"
      chat.push "http://alex.rauchth.eu/ske8/?id=#{drop.id}"
    end
  end
end

$rechats = []

$skype.on(:message_status) do |msg, status|
  unless msg.is_local?
    msg.get_cached(:chatname) do
      $rechats.unshift msg.chat
      $rechats = $rechats.uniq[0...5]
    end
  end
end

SkypeFileTransfer.on(:change, 'status') do |transfer, key, o_status, status|
  if status == :completed
    process_drop transfer
  end
end

=begin
$callback = nil
$active_chat = nil

SkypeChat.on(:change, 'activity_timestamp') do |chat|
  if $callback
    c = $callback
    $callback = nil
    c.call chat
  else
    $active_chat = chat
  end
end

def when_chat(&callback)
  if $active_chat
    a = $active_chat
    $active_chat = nil
    callback.call a
  else
    $callback = callback
  end
end

SkypeFileTransfer.on(:change, 'status') do |transfer, key, o_status, status|
##puts status.inspect
  $active_chat = nil
  if status == :completed
    transfer.get(:filename, :filepath, :partner_handle) do |f,p,h|
      when_chat do |chat|
        chat.push "#{f.inspect} #{p.inspect}"
      end
    end
  end
end
=end