# You can do this:
# $eval API.process.class.send(:define_method, "push") { |t, &c| self[:stdout].push (cmd == 'retard' ? t : API.exec("$retard #{t}")[0]), &c }

module FP
  class Pipe
    def initialize(out); @out = out; end
    def push(t); @out.puts t; end
  end
  
  class Process
    attr_accessor :thread, :cmd, :arg, :pid, :children, :parent, :start_time, :environment, :chat, :threads
    attr_reader :owner, :coder
    
    attr_accessor :self_time, :cpu_usage
    def cpu_s; @cpu_usage.percent_s; end
    
    def set_coder(v); @coder = v; end
    
    def initialize(chat, parent_thread, owner, cmd, arg, env={})
      #puts "Spawning #{cmd} for #{owner} as child of #{parent_thread}..."
      
      if Thread.current.thread_variable?(:process)
        puts "*** Thread is already linked to a process."
        exit
      end
      
      Thread.current.thread_variable_set(:process, self)
      
      @parent = parent_thread.thread_variable_get(:process) unless parent_thread == nil
      @parent.register_child(self) unless @parent == nil
      
      @self_time = 0.0
      @cpu_usage = 0.0
      
      @chat = chat
      @start_time = Time.now
      @thread = Thread.current
      @owner = owner
      @coder = owner
      @cmd = cmd
      @arg = arg
      @pid = $pid_counter
      @children = []
      @environment = env
      @threads = []
      
      $pid_counter += 1
      $processes[@pid] = self
    end
    
    def create_thread(&l)
      thread = Thread.new &l
      thread.thread_variable_set(:process, self)
      @threads << thread
    end
    
    def poll; self[:stdin].poll; end
    def push(t, &c); self[:stdout].push t, &c; end
    
    def register_child(child)
      @children << child
    end
    
    def unregister_child(child)
      @children.delete child
    end
    
    def kill
      @parent.unregister_child(self) unless @parent == nil
      $processes.delete @pid
      
      count = 1
      tcount = 0
      
      #puts "Killing #{@pid}, #{@children.length} children."
      @children.each do |child|
        x = child.kill
        count += x[0]
        tcount += x[1]
      end
      
      @threads.each { |thread| thread.kill; tcount += 1 }
      @thread.kill # Ensure the thread is also dead.
      
      return count, tcount
    end
    
    def tree_count
      count = 1
      @children.each { |child| count += child.tree_count }
      count
    end
    
    def tree_depth
      depth = 1
      @children.each do |child|
        d = child.tree_depth + 1
        depth = d if d > depth
      end
      depth
    end
    
    def get_env_var(var)
      return @environment[var] unless @environment[var] == nil
      return @parent.get_env_var(var) unless @parent == nil
      return nil
    end
    
    def set_env_var(var, val)
      return parent.set_env_var(var, val) if @parent != nil and var[0] == '+'
      return @environment[var] = val
    end
    
    def [](k); get_env_var k; end
    def []=(k,v); set_env_var k, v; end
    
    def to_s
      "<#{@pid}:#{@cmd}>"
    end
    
    def self.current
      t = Thread.current
      t = $root_thread unless t.thread_variable?(:process)
      t.thread_variable_get :process
    end
    
    def self.process_for_thread(t)
      t.thread_variable_get :process
    end
  end
  
  class FakeMessage
    def initialize(bmsg, bchat); @bmsg = bmsg; @bchat = bchat; end
    def chat; @bchat; end
    
    protected
    def method_missing(name, *args, &block)
      puts "miss:#{name.inspect}"
      @bmsg.send(name, *args, &block)
    end
  end
  
  class FakeChat
    attr_accessor :buffer
    def initialize(bchat); @bchat = bchat; @buffer = []; end
    def push(msg)
      @buffer << msg
    end
    
    protected
    def method_missing(name, *args, &block)
      @bchat.send(name, *args, &block)
    end
  end
end