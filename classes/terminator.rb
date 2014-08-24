require 'ruby-prof'

class Terminator
  @@internal_threads = []
  @@load = 0
  @@load_public = 0
  @@abuses = Hash.new 0
  @@pmon = Hash.new []
  
  @@thread_list = []
  @@load_per_user = Hash.new 0
  
  def self.load; @@load; end
  def self.pmon; @@pmon; end
  def self.load_per_user; @@load_per_user; end
  
  def self.cycle
    RubyProf.start # Crashes possible.
    @@thread_list = Thread.list
    
    sleep 0.6
    
    result = RubyProf.stop
    
    full_load = 0
    
    pmon = {}
    result.threads.each do |prof|
      time = prof.top_methods.map(&:self_time).reduce(&:+)
      next if time == nil # WTF?
      
      full_load += time
      
      thread = @@thread_list.find { |t| t.object_id == prof.id }
      next if thread == nil # WTF? If this happens we are doomed.
      process = FP::Process.process_for_thread thread
      next if process == nil # Not a process-thread? Straaaaange.
      
      pmon[process] = time
    end
    
    @@load = full_load
    @@pmon = pmon.dup
    @@pmon.freeze
    @@load_per_user = Hash.new 0
    
    pmon.delete $root_process # [Terminator] Killing fremdpartikel due to high load (was using 100.00% cpu).
    return if pmon.empty?
    
    @@load_per_user = pmon.reduce(Hash.new 0) { |h,(process,cpu_time)| h[process.owner] += cpu_time; h }
    @@load_per_user.freeze
    
    @@load_per_user.each do |(user, cpu_time)|
      if cpu_time > 0.025 # This user causes a high load
        processes = pmon.select { |(process,v)| process.owner == user } # Find all processes for this user
        process, self_time = pmon.max_by { |(k,cpu_time)| cpu_time } # Find the greediest process
        terminate process, :reason => :user_load
      end
    end
    
    @@load_public = pmon.values.reduce(&:+)
    pmon.each do |(process, time)|
      process.self_time = time
      process.cpu_usage = time / @@load_public
    end
    
    if @@load >= 0.1 # High System Load - Well, that sucks.
      process, self_time = pmon.max_by { |(k,v)| v }
      terminate process, :reason => :system
    end
  end
  
  def self.terminate(process, **params)
    reason = case params[:reason]
      when :user_load then ' by user'
      when :system    then ' by system'
      else ''
    end
    
    process.push "[Terminator] Killing #{process.cmd} due to high load#{reason} (was using #{process.cpu_s} cpu)."
    process.kill
    
    @@abuses[process.owner] += 1
    case @@abuses[process.owner]
      when 3 then process.push "[Terminator] Consider this as a warning, #{process.owner}."
      when 4 then process.push "[Terminator] Last warning, #{process.owner}."
      when 5 then
        process.push "[Terminator] You have been blacklisted, #{process.owner}."
        SkypeUser.new($skype, process.owner).push "Have a nice day, Sir."
        $blist << process.owner # TODO: This makes no sense. Ha. Haha.
    end
  end
  
  def self.register_thread(thread); @@thread_list << thread; end
  
  def self.start
    @@internal_threads << Thread.new do
      while true
        begin
          cycle
        rescue => e
          puts e.inspect
          puts e.backtrace.inspect
        end
        
        sleep 0.1 + rand(30) / 100.0
      end
    end
    
    @@internal_threads << Thread.new do
      while true # Every minute, forget about one abuse for every abuser.
        @@abuses.each { |k,v| v -= 1}
        @@abuses.delete_if { |k,v| v == 0 }
        sleep 60
      end
    end
  end
  
  def self.stop
    @@internal_threads.each &:kill
    @@internal_threads = []
  end
end

Terminator.start