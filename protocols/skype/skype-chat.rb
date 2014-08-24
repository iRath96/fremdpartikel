class SkypeChat < Chat
  include SkypeObject
  
  api :chat, 'CHAT'
  
  key:messages => :chatmessages
  key:recent_messages => :recentchatmessages
  key:cmems => :memberobjects
  key:chat_members => :memberobjects
  
  int :activity_timestamp
  str :topic, :name, :guidelines
  sym :status
  
  u_arr :members, :activemembers # TODO: HEY. -- December, 16th: wtf did I mean with 'HEY.'?
  val(:memberobjects) { |v,f,s| f ?
    v.split(' ').map { |id| SkypeMember.withId s, id } :
    v.map { |user| user.id }.join(' ')
  }
  
  def push(msg, &block)
    msg = prepass msg
    (0x00...0x20).each { |i| next if [ 0x09, 0x0a, 0x0d ].include? i; msg.gsub! i.chr, "\\x0#{i.to_s 16}" }
    @skype.command "CHATMESSAGE #{@id} #{msg}" do |cmd, (id)|
      block.to_proc.call SkypeMessage.withId(@skype, id) if block_given?
    end
  end
  
  # TODO: KICKBAN
  def kick(*names, &block); @skype.command "ALTER CHAT #{@id} KICK #{names.join ', '}", &block; end
  def add(*names, &block); @skype.command "ALTER CHAT #{@id} ADDMEMBERS #{names.join ', '}", &block; end
  def topic=(t, &block); skype.command "ALTER CHAT #{@id} SETTOPIC #{t}", &block; end
  def topic_xml=(txt, &block); @skype.command "ALTER CHAT #{@id} SETTOPICXML #{txt}", &block; end
  def guidelines=(g, &block); @skype.command "ALTER CHAT #{@id} SETGUIDELINES #{g}", &block; end
  def leave!(&block); @skype.command "ALTER CHAT #{@id} LEAVE", &block; end
  
##alias_method :send, :push # Deprecated!
  
  def get_messages(&block)
    get(:messages) do |msgs|
      msgs = msgs.split ', '
      msgs.map! { |id| SkypeMessage.withId @skype, id.to_i }
      block.to_proc.call msgs
    end
  end
  
  def get_recent_messages(&block)
    get(:recent_messages) do |msgs|
      msgs = msgs.split ', '
      msgs.map! { |id| SkypeMessage.withId @skype, id.to_i }
      block.to_proc.call msgs
    end
  end
  
  def name; @id; end # Implementing Chat#name is required.
end