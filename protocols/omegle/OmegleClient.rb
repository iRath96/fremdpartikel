def craftFlText(string); [ string.length ].pack('n') + string; end
def readFlText(context, index)
  length = context[index ... (index += 2)].unpack('n')[0]
  string = context[index ... (index += length)]
  return string, index
end

def craftFlString(string); [ string.length ].pack('C') + string; end
def readFlString(context, index)
  length = context[index ... (index += 1)].unpack('C')[0]
  string = context[index ... (index += length)]
  return string, index
end

class OmegleClient
  attr_accessor :alive, :socket, :interests, :has_partner, :common_interests
  attr_accessor :buffer, :callbacks
  attr_accessor :typing, :partner_typing
  
  def on(name, &block)
    @callbacks[name] = block
  end
  
  def fire(name, arg)
    puts "(#<#{self.class.to_s}:0x#{self.object_id.to_s 16}>#fire) #{name}" if $DEBUG
    c = @callbacks[name]
    c.call(arg) unless c == nil
  end
    
  def initialize(interests, socket = nil)
    @callbacks = {}
    @buffer = ""
    
    @common_interests = false
    @typing = false
    @partner_typing = false
    @has_partner = false
    
    @interests = interests
    @alive = true
    @socket = socket
    @socket = TCPSocket.new($omegle_ip, $omegle_port) if @socket == nil
    
    tstr = interests ? "&topics=" + CGI::escape(json_encode(interests)) : ""
    
    send_packet "omegleStart",
      "web-flash" +
      "?caps=recaptcha" +
      "&lang=#{ARGV[0]}" + 
      "&spid=" +
      tstr +
      "&abtest=" + OmegleClient::GenerateABTest()
    fire :boot, ''
  end
  
  def update
    begin
      @buffer += @socket.recv_nonblock 4096
    rescue Errno::EAGAIN => e
    end
    
    read_packet while @buffer.length > 0
  end
  
  def read_packet
    command, index = readFlString @buffer, 0
    payload, index = readFlText   @buffer, index
    
    @buffer = @buffer[index .. -1]
    
    puts command.inspect + ";" + payload.inspect if $DEBUG
    case command
      when 'w'
        fire :welcome, payload
      when 'c'
        @has_partner = true
        fire :found_partner, payload
      when 'count'
        fire :got_count, payload.to_i
      when 'commonLikes'
        @common_interests = json_decode(payload)
        fire :got_common_interests, @common_interests
      when 't'
        @partner_typing = true
        fire :partner_typing, @partner_typing
      when 'st'
        @partner_typing = false
        fire :partner_typing, @partner_typing
      when 'm'
        @partner_typing = false
        fire :got_message, payload
        fire :partner_typing, @partner_typing
      when 'd'
        @alive = false
        @has_partner = false
        
        fire :partner_quit, payload
        fire :ended, payload
      when 'client_id'
        # idc.
      when 'recaptchaRequired'
        puts '-'
        fire :captcha_required, payload
        @alive = false
        
        sleep $recaptcha_wait
        
        fire :ended, payload
      else
        puts "UNKNOWN: #{command}" if $DEBUG
        fire :got_unknown_command, [ command, payload ]
    end
  end
  
  def send_typing(typing)
    @typing = typing
    send_packet typing ? 't' : 'st', ''
  end
  
  def send_packet(command, payload)
  ##puts "#{command} sent"
    @socket.write craftFlString(command) + craftFlText(payload)
  end
  
  def send_message(message)
    @typing = false
    send_packet 's', message
  end
  
  def quit
  ##puts "Killing #{self.inspect}"
    @alive = false
    send_packet 'd', ''
  end
  
  def self::GenerateABTest
    "746573743d26756e69713d3133333430"+
    "31393634383436383334303630312674"+
    "6573747365743d313333333737393130"+
    "302e32267465737474733d3133333430"+
    "3139363438"
  end
end