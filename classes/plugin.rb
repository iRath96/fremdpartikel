class PluginBase < Dispatcher
  @@all_commands = {}
  @@plugins = []
  @@errors = []
  
  @@singleton = nil
  def self.singleton; @@singleton; end
  
  def self.Skype=(skype) # TODO: This isn't really needed anymore!
    @@singleton = PluginBase.new if @@singleton == nil
    skype.on(:message_status) do |msg, status|
      msg.get_cached(:from_handle) do |h|
        break if blacklisted? msg.from_handle
        #@@singleton.fire :msg, '', msg if msg.is_new? && !msg.is_local?
      end
    end
  end
  
  def self.init(name)
    @@plugins << self
    
    class_variable_set :@@meta, { :id => name, :bridge => 1.0 }
    class_variable_set :@@commands, {}
    class_variable_set :@@loaded_on, Time.now
    class_variable_set :@@vfs, nil
    class_variable_set :@@default, {}
  end
  
  def self.init_v2(name)
    self.init name
    self.extend Fremdpartikel
    
    class_variable_get(:@@meta)[:bridge] = 2.0
  end
  
  def self.init_vfs(**params)
    safe = self.id.to_s.gsub(/[^a-z0-9_\-.]/i, '')
    path = "data/vfs-ext/#{safe}.vfs"
    
    unless File.exists? path
      vfs = VFS::VFS.new path, true
      vfs.format
      vfs.save
    end
    
    vfs = VFS::VFS.new(path, true)
    vfs.set_params **params
    
    class_variable_set :@@vfs, vfs
  end
  
  def self.vfs; class_variable_get(:@@vfs); end
  
  def self.name; class_variable_get(:@@meta)[:name]; end
  def self.deprecated?; class_variable_get(:@@meta)[:bridge] == 1.0; end
  def self.loaded_on; class_variable_get(:@@loaded_on); end
  
  def self.hide(*cmds)
    if cmds[0] == :*
      class_variable_get(:@@commands).each { |(key,cmd)| cmd.hidden = true }
    else
      cmds.each { |cmd| @@all_commands[cmd].hidden = true }
    end
  end
  
  def self.plugin(id)
    found_plugin = nil
    
    if id.class == Symbol
      @@plugins.each { |plugin| if plugin.id == id; found_plugin = plugin; break; end }
    else
      @@plugins.each { |plugin| if plugin.name == id; found_plugin = plugin; break; end }
    end
    
    found_plugin
  end
  
  def self.meta(m)
    meta = class_variable_get(:@@meta)
    meta.merge!(m) unless m == nil
    meta
  end
  
  def self.method_missing(meth, *args, &block)
    meta = class_variable_get(:@@meta)
    return meta[meth] unless meta[meth] == nil
    super
  end
  
  def self.plugins; @@plugins; end
  
  def self.api(cmd, &callback)
    API.define_singleton_method(cmd.to_sym, &callback)
    self.define_singleton_method("cmd_#{cmd}".to_sym) { |m,d| callback.call d }
  end
  
  def self.default(**h) # Sets the default params hash for self.cmd
    class_variable_set :@@default, h
  end
  
  def self.cmd(cmd, description = '', usage = '', **params)
    cmd_name = cmd.to_sym
    cmd = @@all_commands[cmd_name]
    
    params = class_variable_get(:@@default) + params
    params[:quota] = [ params[:quota] ] if params[:quota] and not params[:quota][0].is_a? Array
    
    if cmd == nil
      plugcmd = PluginCommand.new cmd_name, description, self
      plugcmd.usage = usage
      plugcmd.rank = (params[:rank] or :user)
      plugcmd.quota = (params[:quota] or [])
      
      @@all_commands[cmd_name] = plugcmd
      class_variable_get(:@@commands)[cmd_name] = plugcmd
    else
      if cmd.defined_by == self # Update the information
        cmd.description = description
        cmd.usage = usage
        cmd.rank = (params[:rank] or :user)
        cmd.quota = (params[:quota] or [])
      else
        error "#{self.name} tries to define command #{cmd_name.inspect} " + 
              "which is already defined by #{cmd.defined_by.name}. No changes applied."
      end
    end
  end
  
  def self.has_command?(cmd)
    commands.include? cmd.to_sym
  end
  
  def self.unregister_cmd(cmd) # Drop the entry for this command.
    cmd = cmd.to_sym
    
    @@all_commands.delete cmd
    class_variable_get(:@@commands).delete cmd
  end
  
  def self.aka(cmd, new_cmd)
    @@all_commands[new_cmd] = @@all_commands[cmd]
  end
  
  def self.hook(cmd, &block)
    @@singleton = PluginBase.new if @@singleton == nil
    @@singleton.on :msg, &block
  end
  
  def self.commands
    class_variable_get (self == PluginBase ? :@@all_commands : :@@commands)
  end
  
  def self.[](i)
    self == PluginBase ? @@all_commands[i] : class_variable_get(:@@commands)[i]
  end
  
  def self.error(str)
    @@errors << str
    puts str.inspect
  end
  
  def self.unload
    # Going to shutdown.
    @@plugins.each do |plugin|
      plugin.uninstall if plugin.methods.include? :uninstall
    end
  end
end

class PermissionError < Exception; end
class PluginCommand
  @@invoke_count = Hash.new 0
  include Persistence
  
  attr_accessor :name, :description, :defined_by
  attr_accessor :invoke_count, :last_invoke, :usage
  attr_accessor :hidden, :rank, :quota
  
  def initialize(*args)
    @name, @description, @defined_by = args
    @invoke_count = 0
    @last_invoke = false
    @rank = :user
    @quota = []
  end
  
  def invoke(user, *a, &b)
    raise PermissionError if user.rank < @rank
    @quota.each do |(k,cost)|
      Quota.register k, cost
    end
    
    @@invoke_count[@name] += 1
    @invoke_count += 1
    @last_invoke = Time.now
    
    m = @defined_by.method("cmd_#{@name.to_s.gsub '-', '_'}".to_sym)
    if m.parameters.length == 0
      m.call # A modern method using the new Fremdpartikel bridge :)
    else
      m.call(*a, &b)
    end
  end
  
  def total_invoke_count; @@invoke_count[@name]; end
  def invoke_s; "invoked #{@invoke_count} times (#{total_invoke_count} times in total)"; end
  
  def to_s; "#{defined_by.name}<#{name}>"; end
  
  def self.invokes; @@invoke_count.reduce(0) { |r,(k,v)| r+v }; end
end

at_exit do
  PluginBase.unload
end