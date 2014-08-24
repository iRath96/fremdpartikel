#encoding=utf-8

module StatsPlugin
  class Plugin < PluginBase
    init_v2 :stats
    
    meta :name => "Stats Plugin",
         :author => "Paul Clement Côté & Alexander Rath",
         :version => -42.0,
         :description => "@stats messages"
    
    cmd :pie, "Test Math::PIe-charts", "@Math::PIe"
    
    def self.cmd_pie
      sp_len = data == 'win' ? 3 : 4
      
      # Windows:
      #  dot: 4px, space: 3px
      # OS X:
      #  dot: 4px, space: 4px
      
      bitmap = []
      (0 ... 64).each do |x|
        bitmap[x] = []
        (0 ... 64).each do |y|
          bitmap[x][y] = false
        end
      end
      
      (0 ... 360).each do |d|
        x = (Math.cos(d * Math::PI / 180) * 30 + 32).round
        y = (Math.sin(d * Math::PI / 180) * 30 + 32).round
        
        x = 63 if x > 63
        y = 63 if y > 63
        
        bitmap[x][y] = true
      end
      
      (0 ... 64).each do |i|
        bitmap[i][i] = true
        bitmap[63-i][i] = true
      end
      
      result = ''
      
      step = 9
      height = 24
      
      (0 .. height).each do |y|
        result += "| "
        
        x = 0
        while x < 64 * step
          val = bitmap[(x / step).round][(y * 64 / height).round]
          result += val ? '.' : ' '
          x += val ? 4 : sp_len
        end
        
        result += "\n"
      end
      
      notify "\n" + result
    end
  end
end