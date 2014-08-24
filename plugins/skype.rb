puts "TODO: Fix this stuff."
module SkypePlugin
  class Plugin < PluginBase
    init_v2 :skype # TODO: Port the usages
    
    default :quota => [ self, 2 ]
    
    meta :name => "Skype Plugin",
         :author => "Alexander Rath",
         :version => 0.6,
         :description => "A bridge to send friend-requests in Skype, to create chat-groups, to spy on other chats, etc."
    
    cmd :topic, "Get/Set the topic of the chat", "(optional: string, otherwise read)"
    cmd :guide, "Get/Set the guidelines of the chat", "(optional: string, otherwise read)"
    
    cmd :'skype-user', "Display information about a Skype user", "skype_handle"
    cmd :'skype-find', "Search for users", "name"
    
    cmd :'skype-friend', "Add a user on Skype", "skype_handle"
    cmd :'skype-unfriend', "Unfriend a user on Skype", "skype_handle"
    
    cmd :msg, "Message one or more SkypeUser(s)", "@msg l1nux121 echo123 lofhy2"
    cmd :spam, "Spam some users", "@spam"
    
    cmd :role, "Gets/Sets the role of a user.", "@role lofhy2 LISTENER"
    cmd :roles, "Displays all roles in the chat.", "@roles"
    
    cmd :'skype-ping', "Ping a SkypeUser", "@skype-ping jameswoodss"
    cmd :'skype-ping-all', "Ping all SkypeUsers in a conversation", "@skype-ping-all [detail]"
    
    cmd :sup?, "Display the mood-messages of all chat-members", "@sup? [detail]"
    cmd :add, "Add a SkypeUser to the conversation", "@add echo123"
    cmd :kick, "Kick a SkypeUser from the conversation", "@kick echo123"
  ##cmd :ranks, "Check everybody's rank", "@ranks [detail]"
    cmd :repeat, "Repeat what you just said", "@repeat"
    
    cmd :alert, "Alert a user.", "@alert l1nux121 Your new wig shipped!", :quota => [ self, 5 ]
    cmd :join, "Join a chat.", "@join #lofhy2/$fremdpartikel;9f25240f2e627a16", :quota => [ self, 5 ]
    hide :join
    
    cmd :count, "Count messages.", "@count irath96 %"
    cmd :countall, "Count messages.", "@countall %"
    cmd :quote, "Quote a user.", "@quote irath96"
    cmd :spsp, "Spam.", "@spsp 100", :quota => [ self, 10 ]
    
    cmd :sam, "Sam mode.", "@sam"
    cmd :moo, "Moo.", "@moo"
    cmd :avatar, "Avatar.", "@avatar"
    
    def self.cmd_moo # Wait, what's the point of this? I don't even ?! wtf.
      $skype.set :fullname, "#{data}"
    end
    
    def self.cmd_avatar
      $skype.cmd("GET USER #{data} AVATAR 1 /Users/Shared/avatars/temp.jpg") do
        notify "Got avatar."
      end
    end
    
    def self.cmd_sam
      a = []
      
      q = $mysql.query "SELECT `body` FROM `msgs` WHERE `type` = 'SAID' AND `from_handle` = 'sam1337x' AND (`body` LIKE '%fuck%' OR BINARY `body` = BINARY UPPER(`body`) OR `body` like '%suck%' OR `body` LIKE '%smell%' OR `body` LIKE '%mom%' OR `body` LIKE '%pus%')"
      
      while (h = q.fetch_hash)
        a << h
      end
      
      q.free
      
      40.times do
        msg.chat.push a.sample["body"]
        sleep 0.1 + rand(7) / 5.0
      end
    end
    
    def self.cmd_countall
      d = data
      m = msg
      pref = prefix
      
      msg.chat.get(:members) do |members|
        counts = []
        
        members.each do |member|
          counts << cmd_count(msg, member.id + ' ' + d, true)
        end
        
        counts.sort! { |a,b| puts b[0].inspect; puts a[0].inspect; b[0] <=> a[0] }
        m.chat.push "#{pref}Results:\n" +
          counts.map { |(r,h,c,t)| "  #{('%+13s' % h).gsub('  ', '   ').gsub('    ', '     ')}\t: #{c.p_of_s t}\t(every #{'%.2f' % (t.to_f / c)} |\t#{c} out of #{t})" }.join("\n")
      end
    end
    
    def self.cmd_count(msg, data, ret = false)
      handle, body = data.split(" ", 2)
      
      q1 = $mysql.query "SELECT COUNT(`body`) AS `count` FROM `msgs` WHERE `type` = 'SAID' AND `from_handle` LIKE \"#{$mysql.escape_string(handle)}\" AND `body` LIKE \"#{$mysql.escape_string(body)}\""
      h1 = q1.fetch_hash
      q1.free
      
      q2 = $mysql.query "SELECT COUNT(`body`) AS `count` FROM `msgs` WHERE `type` = 'SAID' AND `from_handle` LIKE \"#{$mysql.escape_string(handle)}\""
      h2 = q2.fetch_hash
      q2.free
      
      count = h1["count"].to_i
      total = h2["count"].to_i
      
      total = -1 if total == 0
      
      return [ count.to_f / total, handle, count, total ] if ret
      msg.chat.push "@count #{data} :-  #{count} out of #{total} (every #{'%.2f' % (total.to_f / count)}th message | #{count.p_of_s total})"
    end
    
    def self.cmd_quote
      q = $mysql.query "SELECT * FROM `msgs` WHERE `type` = 'SAID' AND LENGTH(`body`) > 3 AND `from_handle` = \"#{$mysql.escape_string(data)}\" ORDER BY RAND() LIMIT 0,10"
      
      h = []
      
      10.times do
        hash = q.fetch_hash
        break if hash == nil
        hash["timestamp"] = hash["timestamp"].to_i
        h << hash
      end
      
      h.sort! { |a,b| a["timestamp"] <=> b["timestamp"] }
      
      q.free
      
      msg.chat.push h.map { |q| "@quote #{data} :-  #{Time.at(q["timestamp"])}: #{q["body"]}" }.join "\n"
    end
    
    def self.cmd_spsp
      #(0 ... data.to_i).each { |i| notify "SPAM"; sleep 0.1 }
    end
    
    def self.cmd_role
      msg.chat.push "(disabled)"
      #msg.chat.push "/setrole #{data}"
    end
    
    def self.cmd_join
      chat = SkypeChat.withId msg.skype, data
      chat.add msg.sender.id
    end
    
    def self.cmd_spam_DISABLED
      count = data || 100
      
      users = []
      q = $mysql.query "SELECT handle FROM users ORDER BY RAND() LIMIT #{count.to_i}"
      while (h = q.fetch_hash) != nil
        users << h['handle']
      end
      q.free
      
      users.each do |user|
        msg.skype.cmd "MESSAGE #{user} I know what you did last summer!"
      end
      
      msg.chat.push "@spam #{count.to_i} :-  #{users.join ' '}"
    end
    
    def self.cmd_msg
      data.split(' ').each do |id|
        msg.skype.cmd "MESSAGE #{id} I know what you did last summer!"
      end
    end
    
    def self.cmd_topic
      if data == nil
        msg.chat.get(:topic) { |topic| msg.chat.push "@topic :-  #{topic}" }
      else
        msg.chat.topic = data
      end
    end
    
    def self.cmd_guide
      if data == nil
        msg.chat.get(:guidelines) { |guide| msg.chat.push "@guide :-  #{guide}" }
      else
        msg.chat.guidelines = data
      end
    end
    
    def self.cmd_skype_find # TODO: Make this prettier. And remove #city#province, etc
      msg.skype.search_users(data) do |users|
        users.each do |user|
          user.get(:fullname, :country, :province, :city, :about, :sex, :homepage) do |fu,co,pr,ci,ab,se,ho|
            msg.chat.push "@skype-find #{data} :- <#{user.handle}> #{fu} from #{ci},#{pr},#{co} (#{ab}) @ #{ho}"
          end
        end
      end
    end
    
    def self.cmd_skype_friend
      datas.split("\n").each do |data|
        do_add = false
        is_email = data.include? '@'
        
        puts "#{data.inspect} is an email!" if is_email
        
        if data[0] == ?*
          do_add = true
          data = data[1 .. -1]
        end
        
        msg.skype.search_users(data) do |users|
          msg.chat.push "@skype-find #{data} :-  Adding #{users.length} users!"
          if do_add
            users.each { |user| user.add! }
          else
            users.each do |user|
              puts "Found #{user.inspect}"
              begin
                user.fire(:change, :email, 'EMAIL', data, data) if is_email
              rescue => e
                puts e.inspect
              end
              user.get(:fullname, :country, :province, :city, :about, :sex, :homepage) { |*a| }
            end
          end
        end
      end
    end
    
    def self.cmd_skype_unfried
      notify "No permission!"
    end
    
    def self.cmd_skype_user
      user = SkypeUser.withId msg.skype, data
      notify "Hold on..."
      
      user.get(:handle, :fullname, :country, :province, :city) do |handle, fullname, country, province, city|
        notify "handle:#{data}, fullname:#{fullname}, country:#{country}, " +
          "province:#{province}, city:#{city}"
      end
      
      user.get(:phone_home, :phone_office, :phone_mobile, :homepage) do |ph, po, pm, homepage|
        notify "phone_home:#{ph}, phone_office:#{po}, phone_mobile:#{pm}, homepage:#{homepage}"
      end
      
      user.get(:about, :mood_text, :rich_mood_text, :aliases) do |about, mt, rmt, aliases|
        notify "about:#{about}, mood_text:#{mt}, rich_mood_text:#{rmt}, aliases:#{aliases}"
      end
      
      user.get(:timezone, :skypeout, :skypeme) do |timezone, skypeout, skypeme|
        notify "timezone:#{timezone}, skypeout:#{skypeout}, skypeme:#{skypeme}"
      end
      
      user.get(:sex, :onlinestatus, :language) do |sex, onlinestatus, language|
        notify "sex:#{sex}, onlinestatus:#{onlinestatus}, language:#{language}"
      end
      
      user.get(:birthday, :lastonlinetimestamp, :speeddial, :nrof_authed_buddies) do |b, lot, sd, nrof|
        notify "birthday:#{b}, lastonlinetimestamp:#{lot}, speeddial:#{sd}, " +
          "nrof_authed_buddies:#{nrof}"
      end
      
      user.get(:blocked?, :authorized?, :can_leave_vm, :is_cf_active) do |bl, au, lvm, cfa|
        notify "isblocked:#{bl}, isauthorized:#{au}, can_leave_vm:#{lvm}, is_cf_active:#{cfa}"
      end
      
      user.get(:hascallequiptment, :is_video_capable, :is_voicemail_capable, :receivedauthrequest) do |has, vid, vo, rcvd|
        notify "hascallequiptment:#{has}, is_video_capable:#{vid}, " +
          "is_voicemail_capable:#{vo}, receivedauthrequest:#{rcvd}"
      end
    end
    
    def self.cmd_skype_ping
      chrs = [('a' .. 'z'), ('A' .. 'Z'), ('0' .. '9'), '$&/\\()"\'*+-.:;_#'.chars].map{ |i| i.to_a }.flatten
      salt = (0 ... 16).map{ chrs[rand(chrs.length)] }.join
      
      s = Time.now.to_f
      h = "@ping #{salt}"
      
      u = SkypeUser.withId(msg.skype, data)
      u.push h # TODO: Perhaps use the callback method of push
      
      bmsg = msg
      msg.skype.on(:message_status) do |msg, status|
        msg.get_cached(:body) do |body|
          if body == h and status == :sent
            d = Time.now.to_f - s
            bmsg.chat.push "#{prefix}Alive (" + "%2.2f" % d + "s)!"
            :unhook
          end
        end
      end
    end
    
    def self.cmd_skype_ping_all
      msg.chat.get(:members) do |members|
        members.each do |member|
          d = member.handle
          
          msg.push "@skype-ping #{d} :- waiting..."
          cmd_skype_ping msg, d
        end
      end
    end
    
    def self.cmd_sup?
      chat = msg.chat
      chat.get(:members) do |members|
        count = 0
        content = "@sup? :-  Has %count of #{members.length}"
        append = ""
        
        chat.push(content.gsub('%count', '0')) do |msg|
          chat.members.each do |user|
            user.get(:mood) do |mood|
              count += 1
              push = mood != '' || data == '+'
              
              if push
                mood = mood == '' ? '(none)' : "\"#{mood}\""
                msg.body = content.gsub('%count', count.to_s) + (append += "\n@sup? #{user.id} :-  #{mood}")
              end
              
              #if count == chat.members.length
              #  msg.body = ' '
              #  chat.push append[1 .. -1]
              #end
            end
          end
        end
      end
    end
    
    def self.cmd_add
      users = data.split ' '
      
      Quota.register :skype, users.length, :user => process.owner
      msg.chat.add users
    end
    def self.cmd_kick
      users = data.split ' '
      
      Quota.register :skype, users.length, :user => process.owner
      msg.chat.kick users
    end
    
    def self.cmd_repeat
      notify "@repeat :-  Not implemented."
    end
    
    def self.cmd_alert
      h, m = data.split ' ', 2
      SkypeUser.withId(msg.skype, h).push m
    end
  end
end

=begin
SkypeFileTransfer.on(:change, 'status') do |transfer|
  # We cannot accept it... So post a stupid comment :)
  transfer.get(:filename, :partner_handle) do |f,h|
    SkypeUser.withId(transfer.skype, h).push "\"#{f}\", eh? Sounds like a virus!" 
  end
end
=end