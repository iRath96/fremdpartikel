require '../../dispatcher.rb'
require './OmegleClient.rb'
require Dir.home + '/proksis/loader.rb'

Proksis.rehash

$r = [ 'deutsch', 'germany', 'deutschland', 'germany' ]
$pool = []
(0 ... 200).each do
  Thread.new do
    while true
      begin
        o = OmegleClient.new $r, $proksis[:http].choice
        o.start_update_thread
        
        o.on(:status) do |status|
          if status == :connected
            puts "!"
            $pool << o
            sleep 0.5
            o.push "Hi"
          end
        end
      rescue => e
      end
      
      sleep 2
    end
  end
end

$c = 0
while true
  if $pool.length >= 2
    puts "Conn #{$c}!"
    
    a = $pool.shift
    b = $pool.shift
    
    f = File.open("logs/" + Time.now.to_f.to_s + ".txt", "w+")
    
    a.on(:message) { |m| puts "A: #{m}"; f.puts 'A > ' + m; b.push(m) }
    b.on(:message) { |m| puts "B: #{m}"; f.puts 'B > ' + m; a.push(m) }
    
    $c += 1
    a.on(:status) { |s| if s == :disconnected; b.disconnect; f.close; $c -= 1; puts "?"; end }
    b.on(:status) { |s| if s == :disconnected; a.disconnect; f.close; $c -= 1; puts "?"; end }
    
    a.on(:typing) { b.type! }
    b.on(:typing) { a.type! }
  end
  sleep 1
end