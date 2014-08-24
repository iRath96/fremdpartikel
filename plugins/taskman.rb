module TaskmanPlugin
  class Plugin < PluginBase
    init_v2 :taskman
    
    meta :name => "Task-Manager Plugin",
         :author => "Alexander Rath",
         :version => 0.9,
         :description => "Helps managing tasks in fremdpartikel"
    
    cmd:top, "List all running tasks."
    cmd:pkill, "Kill a running task.", "pid"
    cmd:pkillall, "Kill all running tasks matching.", "command_name"
    cmd:pinfo, "Gather information on a process.", "pid"
    cmd:exit, "Exit a process to a certain level within the own process-tree.", "command_name"
    #cmd:load, "Get the current system-load."
    cmd:pmon, "Get performance information for a process.", "pid"
    
    def self.cmd_exit
      pr = process
      while pr.cmd != data
        pr = pr.parent
        return if pr == nil
      end
      
      if pr.cmd == data
        notify "Process found: #{pr}"
        pr.kill
      else
        notify "Not found."
      end
    end
    
    def self.cmd_top
      notify "\n" + process_tree($root_process)
    end
    
    def self.cmd_pkill
      pr = $processes[data.to_i]
      unless pr
        notify "There is no such process with this id."
      else
        unless pr.owner === process.owner #or process.owner == 'irath96'
          notify "You do not own this process."
        else
          notify "#{pr.kill * ' process(es) and '} thread(s) killed."
        end
      end
    end
    
    def self.cmd_pinfo
      process = $processes[data.to_i]
      unless process
        notify "There is no such process with this id."
      else
        env = process.environment.map { |(k,v)| [ k, v.to_s ] }.inspect
        notify "\n  Running for #{(Time.now - process.start_time).time_s}, started by #{process.owner.uid} on #{process[:protocol].name rescue 'Console'}.\n" +
                 "  Command: #{$CMD_SYMBOL}#{process.cmd} #{process.arg}\n" +
                 "  Parent: #{process.parent or '(none)'}\n" +
                 "  Threads: #{process.threads.count}\n" +
                 "  Children: #{process.children.count} (#{process.tree_count-1} sub-processes, #{process.tree_depth-1} processes deep).\n" +
                 "  Self-Time: #{process.self_time} / using #{process.cpu_s} CPU." +
                 "  Environment: #{env}"
      end
    end
    
    def self.cmd_pmon
    
    end
    
  private
    
    def self.process_tree(process, prefix='')
      uptime = (Time.now.to_f - process.start_time.to_f).time_s
      
      owner = "#{process.owner.uid} on #{process[:protocol].name rescue 'Console'}"
      
      pad_pid = ' ' * [ (21 - prefix.length), 0 ].max
      pad_cmd = ' ' * [ ((20 - process.cmd.length) * 1.8077).to_i, 0 ].max
      pad_owner = ' ' * [ ((20 - owner.length) * 1.8077).to_i, 0 ].max
      
      sandboxed = process.thread.safe_level >= 4 ? 'sandboxed' : ''
      
      str = "#{prefix} #{('%04i' % process.pid)+pad_pid}  #{process.cmd+pad_cmd}  #{owner+pad_owner}  #{uptime}  #{process.threads.count} threads  #{process.cpu_s}  #{sandboxed}"
      process.children.each { |child| str += "\n" + process_tree(child, prefix + '  ') }
      str
    end
  end
end