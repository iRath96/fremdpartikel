require 'socket'

class Class
  def subclasses
    ObjectSpace.each_object(Class).select { |c| c < self }
  end
end

$CALLACK_ID_LENGTH = 8
class Skype < SkypeProfile
  attr_accessor :chats, :messages, :users, :callbacks
  attr_accessor :objects
  attr_accessor :status
  
  attr_accessor :connstatus
  
  attr_accessor :bytes_sent, :bytes_received
  
  def initialize(port)
    super(self, nil)
    
    @buffer = ''
    @callbacks = {}
    @objects = {}
    @wmutex = Mutex.new
    
    @bytes_sent = 0
    @bytes_received = 0
    
    @socket = TCPSocket.new '127.0.0.1', port
    
    Thread.new {
      while l = @socket.recv(8192)
        @bytes_received += l.length
        
        @buffer += l
        parts = @buffer.split "\x01", -1
        @buffer = parts.pop
        
        parts.each do |part|
          begin
            puts "\033[1;33m  in: \033[0m#{part}\033[0m"
            handle_command part
            fire :command, part, part
          rescue => e
            puts "Error in the SkypeThread"
            puts e.inspect
            puts e.backtrace.inspect
          end
        end
      end
    }
  end
  
  def cmd(cmd, &block)
    unless block == nil
      id = rand(36 ** $CALLACK_ID_LENGTH).to_s 36
      id = "0#{id}" while id.length < $CALLACK_ID_LENGTH
      
      @callbacks[id] = block.to_proc # Possibly unsafe!
      cmd = "\##{id} #{cmd}"
    end
    
    puts "\033[1;36m out: \033[0m#{cmd}\033[0m"
    #@wmutex.synchronize {
    @socket.puts cmd + "\x01" #}
    @bytes_sent += cmd.length + 1
    
    sleep 0.02
  end
  
  alias_method :command, :cmd
  
  def handle_command(cmd) # TODO: Improve this overall  
    raw = cmd.split(/[ ]/, -1) # Anything else won't work, LOL!
    cmd, *args = raw
    
    hash = ''
    callback = nil
    
    if cmd[0] == ?\#
      hash = cmd[1 .. -1]
      cmd = args.shift
      
      callback = @callbacks[hash]
      @callbacks.delete hash unless callback == nil
    end
    
    cmd.upcase!
    id = args.shift
    
    case cmd
      when 'CONNSTATUS' then @connstatus = id.downcase.to_sym
      when 'USERS' then #fire :users, '', 
      else
        obj = nil
        SkypeObject.subclasses.each do |so_class|
          next if so_class == Skype # This is not a subclass, you know...
          if so_class.responsible_for? cmd
            if so_class.singleton?
            ##puts so_class.inspect
              obj = so_class.new self, ''
            else
              obj = so_class.withId self, id
            end
            break
          end
        end
        
        unless obj == nil
          prop = args.shift.upcase
          obj.info_handler prop, args.join(' ')
        ##obj.fire :info, prop, prop, args.join(' ')
        else
          puts "Excuse me, what is a '#{cmd}'"
        end
    end
    
    begin
      unless callback == nil
        hash, cmd, *args = raw
        callback.call cmd.upcase, args
      end
    ensure
      cmd, *args = raw
      cmd = args.shift unless callback == nil
      
      if cmd == 'MESSAGE' or cmd == 'CHATMESSAGE'
        msg = SkypeMessage.withId self, args.shift.to_i
        fire :message_status, msg.status.to_s, msg, msg.status if args.shift.upcase == 'STATUS'
      end
    end
  end
    
  def status=(stat, &block)
    cmd "USERSTATUS #{stat.to_s.upcase}", &block
  end
  
  def ping(&block)
    cmd "PING", &block
  end
  
  def call(whom, &block)
    cmd "CALL #{whom}", &block
  end
  
  def search_users(needle, &block)
    throw "You need to pass a block for this." if block == nil
    cmd "SEARCH USERS #{needle}" do |cmd, users|
      if cmd.upcase == 'ERROR'
        # TODO: ...?
      else
        block.to_proc.call users.join(' ').downcase.split(', ').map { |handle| SkypeUser.withId self, handle }
      end
    end 
  end
  
  def recent_chats(&block)
    cmd "SEARCH RECENTCHATS" do |cmd, chats|
      block.to_proc.call chats.join(' ').downcase.split(', ').map { |handle| SkypeChat.withId self, handle }
    end
  end
end