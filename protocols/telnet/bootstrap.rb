require 'socket'

class TelnetUser < User
  def initialize; @account = HashResponder.new :uid => 'telnet://alex'; end
end

class TelnetChat < Chat
  def initialize(sock); @sock = sock; end
  def push(t); @sock.puts "\033[38;5;186m  #{t.gsub "\n", "\n  "}\033[38;5;68m"; end
  def name; "telnet"; end
end

class TelnetProtocol < Protocol
  init :telnet
  
  def self.shorten?; false; end
  def self.name; "Telnet"; end
  
  def self.run(**params)
    sock = TCPServer.new params[:ip], params[:port]
    
    while true
      client = sock.accept
      Thread.new { process_client client }
    end
  end
  
  def self.process_client(sock)
    user = TelnetUser.new
    chat = TelnetChat.new sock
    
    sock.print "\033[38;5;68m"
    
    begin
      while true
        m = sock.gets.strip
        
        msg = Message.new Origin.new(user, chat), m
        register_message msg, TelnetProtocol
        
        sleep 0.05
      end
    rescue => e
    ensure
      sock.close
    end
  end
end