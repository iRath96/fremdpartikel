require 'json'

class API
  def self.http_get(url)
    return "Vulnerable. Being fixed soon."
    
    f = open URI.parse(url)
    f.read
  end
end

module RubyPlugin
  require "shikashi"
  include Shikashi
  
  require 'base64'
  require 'open-uri'
  
  require 'PP'
  
  @sandbox = Sandbox.new
  @privileges = Privileges.new
  
  class << self; attr_accessor :sandbox, :privileges; end
  
  #
  # Set up the sandbox
  #
  
  def self.allow_class_methods(klass, *exclude)
    @privileges.object(klass).allow *(klass.methods - Object.methods - exclude)
  end
  
  [ :rand, :sleep, :say, :notify, :lambda ].each { |m| @privileges.allow_method m }
  
  [ Object, Proc, JSON, TrueClass, FalseClass, NilClass, Fixnum, Float, String, Array, Hash, Time, Range, Base64, Math, Symbol, VFS, VFS::FileNode, VFS::FolderNode, Marshal, PObject, PP, MatchData ].each do |c|
    @privileges.instances_of(c).allow_all
    RubyPlugin.allow_class_methods c
    @privileges.allow_const_read c
  end
  
  Thread.new do # Wait for plugins to define their APIs.
    sleep 1
    
    RubyPlugin.allow_class_methods API, :push
    @privileges.allow_const_read API
  end
  
  RubyPlugin.allow_class_methods SkypeMessage
  @privileges.allow_const_read SkypeMessage
  @privileges.instances_of(SkypeMessage).allow *[ :from_handle, :from_dispname, :chatname, :body, :edited_by, :role, :users, :type, :status, :leavereason, :timestamp, :options, :edited_timestamp, :is_editable, :seen, :chat, :sender, :user, :is_new?, :is_local? ]
  
  RubyPlugin.allow_class_methods SkypeChat
  @privileges.allow_const_read SkypeChat
  @privileges.instances_of(SkypeChat).allow *[ :members, :add, :kick ]
  
  RubyPlugin.allow_class_methods SkypeUser
  @privileges.allow_const_read SkypeUser
  @privileges.instances_of(SkypeUser).allow *[ :handle, :fullname, :country, :province, :city, :phone_home, :phone_office, :phone_mobile, :homepage, :about, :mood_text, :rich_mood_text, :aliases, :timezone, :skypeout, :skypeme, :sex, :onlinestatus, :language, :birthday, :lastonlinetimestamp, :speeddial, :nrof_authed_buddies, :isblocked, :isauthorized, :can_leave_vm, :is_cf_active, :hascallequiptment, :is_video_capable, :is_voicemail_capable, :receivedauthrequest, :buddystatus, :add!, :account, :identity, :name, :uid, :rank, :has_rank?, :push ]
  
  (User.subclasses + Chat.subclasses).each do |klass|
    @privileges.instances_of(klass).allow :name, :uid
    @privileges.allow_const_read klass
  end
  
  @privileges.object(Message).allow :user, :chat
  @privileges.allow_const_read Message
  
  @privileges.instances_of(VFS::VFS).allow_all
  RubyPlugin.allow_class_methods VFS::VFS, :new
  @privileges.allow_const_read VFS::VFS
  
  @privileges.instances_of(FP::Process).allow *((FP::Process.instance_methods - Object.instance_methods).find_all do |m|
    m[-1] != '=' and m != :push and m != :register_child and m != :parent and m != :set_coder
  end)
  @privileges.allow_const_read FP::Process
  
  #
  # Class definitions
  #
  
  class Meta
    attr_accessor :created, :last_edit, :revisions
    attr_accessor :name, :usage, :description, :owner, :code
    def initialize(n,u,d,o,c)
      @created = Time.now
      @last_edit = Time.now
      @revisions = 0
      
      @name = n
      @usage = u
      @description = d
      @owner = o
      @code = c
    end
    
    def revise(new_code)
      @code = new_code
      @last_edit = Time.now
      @revisions += 1
    end
  end
  
  class Plugin < PluginBase    
    init_v2 :ruby
    
    meta :name => "Ruby Plugin",
         :author => "Alexander Rath",
         :version => 0.6,
         :description => "Create aliases for ruby commands."
    
    cmd:e, "Eval some code.", "ruby_code+"
    cmd:e=, "Eval some code, display the result", "ruby_code+"
    cmd:def, "Define a ruby command.", "script_name ruby_code+"
    cmd:def?, "Get the definition of a ruby command.", "script_name"
    cmd:drop, "'Drop' a command and let others redefine it.", "script_name"
    cmd:describe, "Describe one of your commands.", "script_name description+" # "@describe potatoe You can use it. Like the force."
    
    @@code = {}
    
    #
    # Command definitions
    #
    
    api :e do |code|
      RubyPlugin::Plugin.run_code code
    end
    
    def self.cmd_e=
      notify RubyPlugin::Plugin.run_code(data)
    end
    
    def self.cmd_def
      cmd, code = data.split ' ', 2
      redef = false
      
      if @@code[cmd] == nil and PluginBase.has_command?(cmd)
        notify "#{$CMD_SYMBOL+cmd} is already defined by #{PluginBase.commands[cmd.to_sym].defined_by.name}."
        return
      end
      
      if @@code[cmd] == nil or (redef = @@code[cmd].owner === process.owner)
        if cmd.include? '_'
          notify "Underscores are not allowed in command names anymore - use hypens instead."
          return false
        end
        
        if redef
          meta = @@code[cmd]
          meta.revise code
        else
          meta = Meta.new(cmd, "(data)", '(no description)', process.owner, code)
        end
        
        publish meta
        notify "#{redef ? 'Redefined' : 'Defined'} #{$CMD_SYMBOL+cmd}."
      else
        notify "Cannot redefine #{$CMD_SYMBOL+cmd}."
      end
    end
    
    def self.cmd_def?
      if @@code[data] == nil
        if PluginBase.has_command?(data)
          notify "#{$CMD_SYMBOL+data} is defined by #{PluginBase.commands[data.to_sym].defined_by.name}."
        else
          notify "#{$CMD_SYMBOL+data} does not exist."
        end
      else
        meta = @@code[data]
        notify "Owned by #{meta.owner.name}, revised #{meta.revisions} times.\n#{meta.code}"
      end
    end
    
    def self.cmd_describe
      cmd, desc = data.split ' ', 2
      return notify "No such command." unless @@code[cmd]
      if @@code[cmd].owner === process.owner
        meta = @@code[cmd]
        meta.description = desc
        
        publish meta
        notify "Described #{$CMD_SYMBOL+cmd}."
      else
        notify "You do not own #{$CMD_SYMBOL+data}."
      end
    end
    
    def self.cmd_drop
      return notify "No such command." unless @@code[data]
      if @@code[data].owner === process.owner
        unpublish @@code[data]
        notify "Undefined #{$CMD_SYMBOL+data}."
      else
        notify "You do not own #{$CMD_SYMBOL+data}."
      end
    end
    
    #
    # Important stuff
    #
    
  private
    
    def self.publish(meta)
      @@code[meta.name] = meta
      cmd meta.name, meta.description, meta.usage
      
      self.define_singleton_method(('cmd_' + meta.name).to_sym) do |msg, data|
        FP::Process.current.set_coder meta.owner
        
        FP::Process.current['arg'] = data
        FP::Process.current['msg'] = msg
        
        run_code meta.code
      end
    end
    
    def self.unpublish(meta)
      @@code.delete meta.name
      unregister_cmd meta.name
    end
    
  public
  
    def self.run_code(code)
      begin
        return RubyPlugin::sandbox.run(RubyPlugin::privileges, code)
      rescue SecurityError => e
        notify "#{e.inspect}"
      rescue Timeout::Error => t
        notify "(timeout)"
      rescue => e
        puts e.inspect
        puts e.backtrace.inspect
        notify "#{e.inspect}"
      end
    end
    
    #
    # Constructor and Destructor
    #
    
  public
    
    def self.install
      Marshal::load(File.open("./data/ruby", 'rb') { |f| f.read }).each { |(name,meta)| self.publish meta } rescue false
    end
    
    def self.uninstall # or 'store'
      File.open("./data/ruby", 'wb+') { |f| f.write Marshal::dump(@@code) } rescue false
    end
    
    #
    
    self.install
  end
end