require 'cinch'
require 'cinch/plugins/identify'

class IRCAccount < Account
  attr_accessor :host, :username
  def initialize(u, h); @host = h; @username = u; end
  def uid; "irc://#{@host}/#{@username}"; end
end

class IRCUser < User
  attr_reader :account
  def initialize(u, n, h)
    @irc_user = u
    @name = n
    @host = h
    
    set_account
  end
  def account
    @account or set_account
  end
private
  def set_account; @account = IRCAccount.new @irc_user.authname, @host if @irc_user.authed?; end
end

class IRCChat < Chat
  def initialize(c, n); @irc_chan = c; @name = n; end
  def push(t); @irc_chan.send t; end
end

class IRCProtocol < Protocol
  init :irc
  
  def self.shorten?; true; end
  def self.name; "IRC"; end
  
  def self.run(**params)
    host = params[:server]
    
    users = Hash.new { |h,k| h[k] = IRCUser.new k, k.nick, host } # TODO: What if the nickname changes?!
    chats = Hash.new { |h,k| h[k] = IRCChat.new k, k.name }
    
    bot = Cinch::Bot.new do
      configure do |c|
        c.nick = params[:nick]
        c.server = params[:server]
        c.channels = params[:channels]
        c.port = params[:port] if params[:port]
        c.ssl.use = (params[:use_ssl] or false)
        
        if params[:server] == 'irc.funkytown.cat'
          c.plugins.plugins = [Cinch::Plugins::Identify]
          c.plugins.options[Cinch::Plugins::Identify] = {
            :username => "fremdpartikel",
            :password => "partikel",
            :type     => :nickserv
          }
        end
      end
    
      on :message do |m|
        user = users[m.user]
        chat = chats[m.channel] rescue nil
        
        msg = Message.new Origin.new(user, chat), m.message
        register_message msg, IRCProtocol
        
        #m.reply "Hello, #{m.user.nick}"
      end
    end
    
    bot.start
  end
end