$DEBUG_LOG = true
$DEBUG_OBJS = false
$USE_CALLBACKS_FOR_GET = true # For legacy versions of Skype

class Array
  #def to_s
  #  '[' + map {|e|e.to_s}*',' + ']'
  #end
end

module SkypeObjectExt
  def api_name; class_variable_get :@@api_name; end
  def sym_name; class_variable_get :@@api_name; end
  def responsible_for?(cmd); self.api_name.include? cmd.upcase; end
  
  def api(sym_name, api_name)
    api_name = [ api_name ] unless api_name.class == Array
    
    class_variable_set :@@sym_name, sym_name
    class_variable_set :@@api_name, api_name.map { |cmd| cmd.upcase }
    class_variable_set :@@redirects, {}
    class_variable_set :@@transforms, {}
    class_variable_set :@@id_type, :string
    class_variable_set :@@is_singleton, false
  end
  
  def singleton; class_variable_set :@@is_singleton, true; end
  def singleton?; class_variable_get :@@is_singleton; end
  
  def numeric_ids; class_variable_set :@@id_type, :numeric; end
  
  def key(info)
    ((from, to)) = info.to_a
    class_variable_get(:@@redirects)[from] = to
  end
  
  def transform(*keys, &using) # v,f,s => value, forth?, skype
    using = using.to_proc
    transforms = class_variable_get :@@transforms
    keys.each { |key| transforms[key] = using }
  end
  
  def bool(*keys)
    keys.each { |k| attr_reader k }
    transform(*keys) { |v,f,s| f ? v.upcase == 'TRUE' : (v ? 'TRUE' : 'FALSE') }
  end
  
  def sym(*keys)
    keys.each { |k| attr_reader k }
    transform(*keys) { |v,f,s| f ? v.downcase.to_sym : v.to_s.upcase }
  end
  
  def int(*keys)
    keys.each { |k| attr_reader k }
    transform(*keys) { |v,f,s| f ? v.to_i : v.to_s }
  end
  
  def str(*keys)
    keys.each { |k| attr_reader k }
  end
  
  def val(*keys, &block)
    keys.each { |k| attr_reader k }
    transform *keys, &block
  end
  
  def u_arr(*keys, &block)
    keys.each { |k| attr_reader k }
    transform(*keys) { |v,f,s| f ?
      v.split(' ').map { |id| SkypeUser.withId s, id } :
      v.map { |user| user.id }.join(' ')
    }
  end
  
  def refine_id(id)
    return case class_variable_get(:@@id_type)
      when :string then id.to_s.downcase
      when :numeric then id.to_i
      else id
    end
  end

  def withId(skype, id)
    raise "Cannot call SkypeObject.withId on a class described as singleton!" if self.singleton?
    
    id = self.refine_id id
    sym = self.sym_name
    
    if skype.objects[sym] == nil
      skype.objects[sym] = {}
    elsif skype.objects[sym][id] != nil
      puts "\033[35;1m obj:\033[0m #{self.name}[#{id}] = cache" if $DEBUG_OBJS
      return skype.objects[sym][id]
    end
    
    puts "\033[35;1m obj:\033[0m #{self.name}[#{id}] = new" if $DEBUG_OBJS
    self.new skype, id
  end
  
  def port_key(key)
    redirects = class_variable_get :@@redirects
    (redirect = redirects[key]) == nil ? key : redirect
  end
  
  def transform_value(key, value, skype, forth = true)
    transform = class_variable_get(:@@transforms)[key]
    transform == nil ? value : transform.call(value, forth, skype)
  end
end

$sk_sub = []
module SkypeObject
  attr_accessor :id, :skype
  
  def self.subclasses; $sk_sub; end
  
  def self.included(base)
    $sk_sub << base
    base.extend SkypeObjectExt
  end
  
  def to_s; "#{self.class.name}[#{@id}]#{super}"; end
  def initialize(skype, id)
    super()
    
    @id = id
    @states = {}
    @skype = skype
    @skype.objects[self.class.sym_name][@id] = self unless self.class.singleton?
  end
  
  def inform_change(key, value); end
  def info_handler(rkey, rvalue) # TODO: Test if this works.
    key = rkey.downcase.to_sym
    value = self.class.transform_value(key, rvalue, @skype)
    
    @states[key] = [ :recv_set, Time.now.to_i ]
    
    v_str = value.is_a?(Array) ? value.map { |e| e.to_s }.to_s : value.to_s
    puts "\033[34m set:\033[0m #{key} to #{v_str} on #{self.to_s}" if $DEBUG_LOG
    
    before = self.instance_variable_get("@#{key.to_s}")
    self.instance_variable_set("@#{key.to_s}", value)
    self.inform_change(key, value)
    
    begin
      fire :change, key, key, before, value
    ensure
      @skype.fire :change, key, key, before, value
      fire :info, rkey, rkey, rvalue # unless $USE_CALLBACKS_FOR_GET
    end
  end
  
  def port_key(key); self.class.port_key(key); end
  def respond_to?(meth); self.port_key(meth) != meth || super; end
  def method_missing(meth, *args, &block)
    om = meth
    
    set = false
    if meth[-1] == ?=
      set = true
      meth = meth[0 ... -1].to_sym
    end
    
    m = self.port_key(meth)
    m = (m.to_s + '=').to_sym if set
    meth = om
    
  ##puts m.inspect
    
    if m != meth
      begin
        return self.method(m).call *args, &block
      rescue NameError => e
      end
    end
    
    return set(meth[0 ... -1].to_sym, args[0], &block) if set
    return super
  end

  def set(what, to, &block)
    what = self.class.port_key(what)
    @states[what] = [ :sent_set, Time.now.to_i ]
    
    # TODO: Test this.
    to = self.class.transform_value(what, to, @skype, false)
    
    what = what.to_s.upcase
    id = self.class.singleton? ? '' : " #{@id}"
    cmd = "SET #{self.class.api_name[0]}#{id} #{what} #{to}" # TODO: Primary api_name
    skype.cmd cmd, &block
  end
  
  def get_cached(*what, &block)
    if what.length > 1
      has   = 0
      needs = what.length
      args  = []
      
      ws = []
      what.each_with_index do |w,i|
        self.get_cached(w) { |val|
          has += 1
          args[i] = val
          
          ws << w
          
          block.to_proc.call *args if has == needs
        }
      end
      
      return
    end
    
    what = self.class.port_key(what[0])
    state = @states[what].to_a
    
    if state[0] == :recv_set
      block.to_proc.call self.instance_variable_get("@#{what.to_s}")
    elsif state[0] == :sent_get
      self.on(:info, what.to_s.upcase) { |name, value|
        block.to_proc.call value
        :unhook
      }
    else
      self.get what, &block
    end
  end
  
  def get(*what, &block)
    if what.length > 1
      has   = 0
      needs = what.length
      args  = []
      
      what.each_with_index do |w,i|
        self.get(w) { |val|
          has += 1
          args[i] = val
          
          block.to_proc.call *args if has == needs
        }
      end
      
      return
    end
    
    what = self.class.port_key(what[0])
    @states[what] = [ :sent_get, Time.now.to_i ]
    
    what = what.to_s.upcase
    id = self.class.singleton? ? '' : " #{@id}"
    
    cmd = "GET #{self.class.api_name[0]}#{id} #{what}" # TODO: Primary api_name
    
    if $USE_CALLBACKS_FOR_GET
      @skype.cmd cmd do |cmd, args|
        if cmd.upcase == 'ERROR'
          id, *args = args
          error = args.join ' '
          
          id = id.to_i
          
          self.fire :error, id.to_s, id, error
          
          if block.arity == 1 # is it |value| or |error, value| ?
            block.to_proc.call nil
          else
            block.to_proc.call({ :id => id, :text => error }, nil)
          end
        else
          id, property, *args = args
          value = self.class.transform_value(property.downcase.to_sym, args.join(' '), @skype)
          
          if block.arity == 1 # is it |value| or |error, value| ?
            block.to_proc.call value
          else
            block.to_proc.call nil, value
          end
        end
      end
    else
      self.on(:info, what) { |name, value|
        block.to_proc.call value
        :unhook
      }
      
      @skype.cmd cmd
    end
  end
end