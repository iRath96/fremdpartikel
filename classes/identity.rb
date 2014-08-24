require 'digest/md5'

class Authentication
  attr_accessor :identity
  def valid?; false; end
  def self.possible?(user); true; end
end

class PasswordAuthentication < Authentication # TODO: Store hashed.
  attr_accessor :reminder
  def initialize(pword, rem=''); @password = hash_password(pword); @reminder = rem; end
  def hash_password(pword); Digest::MD5.hexdigest((('A'..'z').to_a + [ pword ]) * ':'); end
  def valid?(pword, salt=nil)
    return @password == hash_password(pword) if salt == nil
    return Digest::MD5.hexdigest(salt + @password) == pword
  end
end

class AccountAuthentication < Authentication
  @@auths = []
  
  attr_accessor :uid
  def initialize(account); @uid = account.uid; @@auths << self; end
  def valid?(account); @uid == account.uid; end
  def self.possible?(user); user.account != nil; end
  
  def marshal_dump; [ @uid, @identity ]; end
  def marshal_load(array)
    @uid, @identity = array
    @@auths << self
  end
  
  def self.auths_for_account(account)
    @@auths.find_all { |auth| auth.valid? account }
  end
end

#

$mail_prov = [ 'gmail.com', 'hotmail.com', 'gmx.com' ]
class Identity
  @@users = Hash.new nil
  def self.users; @@users; end
  
  include Persistence
  
  def self.can_register?(u,e); register_error?(u,e) == nil; end
  def self.register_error?(username, email)
    email = email.downcase
    
    return [ :username, "Only a-zA-Z0-9_ is allowed, 3-15 characters." ] unless username.match /^[a-zA-Z0-9_]{3,15}$/
    return [ :username, "This username exists already." ] if @@users[username]
    return [ :email, "Sorry, at the moment only #{$mail_prov * '/'} is supported." ] unless $mail_prov.include? email.split('@', 2)[1]
    user = @@users.values.find { |u| u.email == email }
    return [ :email, "This email-address is already registred by '#{user.username}´." ] if user
    return nil
  end
  
  def self.register(username, email) # TODO: This should be synchronized :P
    e = register_error? username, email
    return nil if e # You cannot register this, there is an error.
    Identity.new username, email
  end
  
  def self.with_name(username); @@users[username]; end
  
  #
  
  attr_accessor :rank
  attr_reader :username, :email, :auths
  attr_reader :settings
  
  def initialize(username, email)
    @username = username
    @email = email.downcase
    @auths = []
    @rank = :user
    @settings = {} # TODO: Make use of this.
    
    @@users[username] = self
  end
  
  def allow_auth_by(auth); @auths << auth; auth.identity = self; end
end

# msg => Message
# msg.chat => Chat
# msg.user => User
# msg.origin => Origin # A composition of User&Chat, to be able to use msg.origin.push and msg.origin.poll in the same chat.

# Chat, User implement module Channel
# Channel has push and poll

# User.account either nil or instance of Account

#

# TODO: EmailAuthentication, TokenAuthentication, QuestionAuthentication