require 'mysql'

class HKE8Plugin < PluginBase
  init :hke8
  
  meta :name => "HKE8 Plugin",
       :author => "Alexander Rath",
       :version => 0.5,
       :description => "A bridge to hke8.tk"
  
  cmd:hke8, "Search for a file on HKE8.", "filename+"
  
  def self.init_mysql
    @@mysql = Mysql.connect "127.0.0.1", "root", "", "hke8"
  end
  
  def self.cmd_hke8(msg, data)
    m = '%' + @@mysql.escape_string(data) + '%'
    q = @@mysql.query "SELECT DISTINCT(id), name FROM access WHERE name LIKE \"#{m}\" ORDER BY RAND()"
    hs = []; while h = q.fetch_hash; hs << h; end
    q.free
    
    if hs.length
      out = "@hke8 #{data} :-  #{hs.length} result(s):"
      hs[0...50].each do |h|
        out += "\n** http://hke8.tk/#{h['id']} - #{h['name']}"
      end
      
      msg.chat.push out
    else
      msg.chat.push "@hke8 #{data} :-  No results."
    end
  end
end

HKE8Plugin.init_mysql