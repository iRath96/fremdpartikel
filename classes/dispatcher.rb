class Dispatcher # Update the 'fire'-method if you rename this
  attr_accessor :events
  @@singletons = Hash.new { |h,k| h[k] = Dispatcher.new }
  
  def initialize; @events = Hash.new { |h,k| h[k] = [] }; end
  def unhook(listeners); @events; end # Excuse me?
  def on(*args, &callback)
    event, condition = args
    return event.map { |evt| [ evt, on(evt, condition, *args, &callback)[0] ] } if event.class == Array
    return condition.map { |cond| [ event, on(event, cond, *args, &callback)[0] ] } if condition.class == Array
    (@events[event] << [ callback.to_proc, condition ]).last
  end
  
  def self.on(*args, &callback); self.get_singleton.on *args, &callback; end
  def self.get_singleton; @@singletons[self]; end
  def fire(event, matcher, *args)
    self.class.get_singleton.fire(event, matcher, self, *args) unless self.class == Dispatcher
    @events[event].delete_if do |listener|
      callback, condition = listener
      condition = condition.to_s unless condition.class == Regexp
      
      matched = [ self, true ]
      matched[1] = matcher.to_s.match condition unless condition == nil
      
      ((condition == nil || matched[1]) and (callback.arity > args.length ? callback.call(matched, *args) : callback.call(*args)) == :unhook)
    end
  end
end