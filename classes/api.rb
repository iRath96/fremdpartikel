module Fremdpartikel
  def create_thread(&l); Quota.register(:thread, 2); FP::Process.current.create_thread &l; end
  def process; FP::Process.current; end
  def protocol; FP::Process.current[:protocol]; end
  def connection; FP::Process.current[:connection]; end # TODO: Implement this!
  def msg; FP::Process.current[:msg]; end
  def data; FP::Process.current[:data]; end
  def push(text); Quota.register(:out, 1); process.push text; end
  def prefix; "$<#{process.cmd}> :-  "; end
  def notify(text, &callback); Quota.register(:out, 1); process.push "#{prefix}#{text}", &callback; end
end

#
# Important stuff
#

class Buffer
  attr_accessor :content
  def initialize(b=[]); @content = b; end
  def push(t); @content << t; end
end

class API
  extend Fremdpartikel
  
  def self.run(cmd)
    t = eval_cmd msg, cmd, :with_rank => :user
    t.join
    nil
  end
  
  def self.exec(cmd)
    b = Buffer.new
    t = eval_cmd msg, cmd, :stdout => b, :with_rank => :user
    t.join
    b.content
  end
  
  def self.public_vfs
    VFS::VFS.new 'data/public.vfs'
  end
  
  def self.vfs
    owner = process.coder.uid.gsub('://', '*').gsub('/', '^').gsub(/[^a-z0-9_\-.\^\*]/i, '') # TODO: Vulnerability: Collisions. Append hash.
    path = "data/vfs/#{owner}.vfs"
    
    unless File.exists? path
      vfs = VFS::VFS.new path
      vfs.format
      vfs.save
    end
    
    VFS::VFS.new path, true
  end
  
  def self.remote_vfs(type, name)
    name = name.gsub(/[^a-z0-9_\-.]/i, '')
    path = "data/#{type == :private ? 'vfs' : 'vfs-ext'}/#{name}.vfs"
    
    return nil unless File.exists? path
    
    vfs = VFS::VFS.new path
    return nil unless vfs.get_params[:read] == :public
    
    vfs
  end
end

#
# Interfaces
#

class ProtocolManager
  @@connections = { :skype => [{}] }
  include Persistence
  
  @@protocols = {}
  def self.protocols; @@protocols; end
  def self.connections; @@connections; end
  def self.connections=(v); @@connections = v; end
  
  def self.register_protocol(k, id)
    @@protocols[id] = k
  end
  
  def self.run; @@connections.each { |id,v| v.each { |params| Thread.new { @@protocols[id].run **params } } }; end
  def self.add_connection(id, **params)
    @@connections[id] = [] unless @@connections[id]
    @@connections[id] << params
    Thread.new { @@protocols[id].run **params }
  end
end

class Protocol
  def self.init(id)
    ProtocolManager.register_protocol self, id
  end
end

class HashResponder
  def initialize(**h); @h = h; end
  def method_missing(name, *a, **b, &block); @h[name]; end
  def respond_to?(name); @h.include? name; end
end

class Channel < Dispatcher
  def push; raise NotImplementedError; end
  def pop; raise NotImplementedError; end
end

class User < Channel # Keep in mind this is some sort of 'Session´
  attr_accessor :identity, :account
  attr_accessor :name # TODO: Implement this in Skype ;)
  attr_accessor :session # A hash.
  
  def initialize; super; @session = {}; end
  def logged_in?; @identity != nil; end
  def login(i); @identity = i; end
  def logout!; @identity = nil; end
  def uid; @identity ? "fp://#{@identity.username}" : (account ? account.uid : "anon://#{object_id}"); end
  def rank; @identity ? @identity.rank : :guest; end
  def has_rank?(r); rank >= r; end
  def ===(other); uid == other.uid or self == other; end
  def name; @identity ? @identity.username : uid; end
  
  def _dump(level); "#{@identity.username rescue ''}\x00#{account.uid rescue ''}"; end
  def self._load(arg)
    user = User.new
    
    username, uid = arg.split "\x00"
    user.identity = HashResponder.new :username => username unless username.empty?
    user.account = HashResponder.new :uid => uid unless uid.empty?
    
    user
  end
end

class Chat < Channel
  attr_accessor :name, :precall
  def prepass(msg)
    if precall
      return eval(precall)
    else
      return msg
    end
  end
end

class Origin < Channel
  attr_accessor :user, :chat
  def initialize(u,c); @user = u; @chat = c; end
end

class Message
  attr_accessor :origin, :body
  def initialize(origin, body)
    @origin = origin
    @body = body
  end
  
  def user; @origin.user; end
  def chat; @origin.chat; end
end

class Account
  def uid; end
end

class GenericAccount < Account
  attr_accessor :uid
  def initialize(uid); @uid = uid; end
end