module GuestbookPlugin
  class Plugin < PluginBase
    init_v2 :guestbook
    init_vfs :read => :public
    
    meta :name => "Guestbook Plugin",
         :author => "Alexander Rath",
         :version => 0.6,
         :description => "Leave messages to a user."
    
    cmd:sign, "Sign a guestbook.", "@sign lofhy2 What's up with your laundry?"
    cmd:read, "Read a guestbook.", "@read lofhy2"
    
    @@last_seen = Hash.new 0
    @@flagged = Hash.new false
    
    hook:msg do |msg|
      next # TODO: This has to be rewritten.
      #msg.get_cached(:body, :chatname, :sender_handle) do
        if @@flagged[msg.from_handle] and @@last_seen < Time.now.to_i - 10
          msg.chat.push "[guestbook] You have a new message in your guestbook, #{msg.from_handle}."
        end
        @@last_seen[msg.from_handle] = Time.now.to_i
      #end
    end
    
    def self.cmd_sign
      user, message = data.split ' ', 2
      message.strip!
      
      vfs.root.mkfile user, '', false
      vfs.root[user].append "#{Time.now} — #{process.owner}:\n    #{message.gsub "\n", "\n    "}\n"
      vfs.save
      
      notify "Signed #{user}'s guestbook."
      
      @@flagged[user] = true #if @@last_seen[user] < Time.now.to_i - 180
    end
    
    def self.cmd_read
      @@flagged.delete msg.from_handle if data == msg.from_handle
      begin
        notify "\n  " + vfs.root[data].content.gsub("\n", "\n  ")
      rescue => e
        notify "No such guestbook exists."
      end
    end
  end
end