class SkypeAccount < Account
  attr_accessor :username
  def initialize(u); @username = u; super(); end
  def uid; "skype://#{@username}"; end
end

class SkypeUser < User
  include SkypeObject
  
  api :user, 'USER'
  
  key:mood      => :mood_text
  key:status    => :onlinestatus
  key:gender    => :sex
  key:blocked?  => :isblocked
  key:relation    => :buddystatus
  key:full_name   => :fullname
  key:is_blocked  => :isblocked
  key:authorized?   => :isauthorized
  key:buddy_status  => :buddystatus
  key:is_authorized => :isauthorized
  key:last_online   => :lastonlinetimestamp
  
  str :handle, :fullname, :country, :province, :city, :phone_home, :phone_office, :phone_mobile
  str :homepage, :about, :mood_text, :rich_mood_text, :aliases, :timezone
  str :skypeout, :skypeme # Unsure
  
  sym :sex, :onlinestatus, :language
  
  int :birthday, :lastonlinetimestamp, :speeddial, :nrof_authed_buddies # TODO: Own value-transformation for this.
  
  bool :isblocked, :isauthorized, :can_leave_vm, :is_cf_active, :hascallequiptment, :is_video_capable
  bool :is_voicemail_capable, :receivedauthrequest
  
  val(:buddystatus) { |v| [ :unrelated, :deleted, :pending, :friend ][v.to_i] }
  
  def initialize(skype, id); super; @handle = id; end
  def add!(&block); set(:relation, 2, &block); end # TODO: How about :pending here?
  def push(msg, &block); @skype.cmd "MESSAGE #{@id} #{msg}", &block; end
  def account; SkypeAccount.new @handle; end
end