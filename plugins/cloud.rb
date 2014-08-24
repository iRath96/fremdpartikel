require 'mysql'
module CloudPlugin
  class Plugin < PluginBase
    init_v2 :cloud
    
    meta :name => "Cloud Plugin",
         :author => "Alexander Rath",
         :version => 0.7,
         :description => "A bridge to cl.ly"
    
    cmd:'cl-find', "Find a drop by filename; '%' = placeholder", "@cl-find %.jpg"
    cmd:'cl-comment', "Comment on a drop", "@cl-comment 4hn1 Interesting picture of a cake."
    cmd:'cl-rate', "Rate a drop from +5 to -5", "@cl-rate 4hn1 +5"
    cmd:'cl-info', "Get information on a drop", "@cl-info 4hn1"
    cmd:'cl-random', "Find a random drop", "@cl-random .jpg"
    cmd:'cl-comments', "What about @cl-rates?", "@cl-comments"
    
    def self.init_mysql
      @@mysql = Mysql.connect "127.0.0.1", "root", "", "cloudbin"
    end
    
    def self.find_drops(data, sort=false)
      puts sort.inspect
      
      m = '%' + @@mysql.escape_string(data) + '%'
      q = @@mysql.query "SELECT * FROM drops WHERE filename LIKE \"#{m}\"" + (sort ? " ORDER BY sk_rate_avg DESC" : " ORDER BY RAND()")
      hs = []; while h = q.fetch_hash; hs << h; end
      q.free
      
      hs
    end
    
    def self.cmd_cl_random
      hs = find_drops (data or '')
      h = hs[rand(hs.length)]
      
      type = 'outgoing'
      
      v = h['sk_rate_avg'].to_i
      v = v > 0 ? '+' + v.to_s : v.to_s
      
      c = h['sk_rate_count'].to_s
      
      notify "http://cl.ly/#{h['id']} [#{v} : #{c} votes] (#{type}) - #{h['filename']}"
    end
    
    def self.cmd_cl_find(msg, data)
      puts data.inspect
      
      data = '' if data == nil
      
      sort = data[0] == '?'
      data = data[1..-1] if sort
      
      hs = find_drops data, sort
      
      lines = [ "Found #{hs.count} items: " ]
      hs.slice(0, 20).each do |h|
        type = 'outgoing'
        
        v = h['sk_rate_avg'].to_i
        v = v > 0 ? '+' + v.to_s : v.to_s
        
        c = h['sk_rate_count'].to_s
        com_count = fetch_comments(@@mysql.escape_string(h['id'])).count
        
        lines << "- http://cl.ly/#{h['id']} [#{v} : #{c} votes | #{com_count} comments ] (#{type}) - #{h['filename']}"
      end
      
      notify lines.join("\n")
    end
    
    def self.cmd_cl_comment
      id, comment = data.split(' ', 2)
      
      val  = '"' + @@mysql.escape_string(id) + '",'
      val += '"' + @@mysql.escape_string(msg.from_handle) + '",'
      val += Time.now.to_i.to_s + ','
      val += '"' + @@mysql.escape_string(comment) + '"'
      
      @@mysql.query "INSERT INTO comments (`drop_id`, `handle`, `time`, `comment`) VALUES (#{val})"
      update_drop id
      
      notify "Posted!"
    end
  
    def self.cmd_cl_rate
      id, rate = data.split(' ', 2)
      rate = rate.to_i
      
      if rate < -5 or rate > +5
        msg.chat.push "@cl-rate #{id} :-  Nice try, #{msg.from_handle}!"
        return
      end
      
      id_filtered = @@mysql.escape_string(id)
      handle_filtered = @@mysql.escape_string(msg.from_handle)
      
      val  = '"' + id_filtered + '",'
      val += '"' + handle_filtered + '",'
      val += Time.now.to_i.to_s + ','
      val += rate.to_s
      
      @@mysql.query "DELETE FROM rates WHERE drop_id = \"#{id_filtered}\" AND handle = \"#{handle_filtered}\""
      @@mysql.query "INSERT INTO rates (`drop_id`, `handle`, `time`, `rate`) VALUES (#{val})" unless rate == 0
      
      update_drop id
      
      notify "Posted!"
    end
    
    def self.update_drop(id)
      id = @@mysql.escape_string(id)
      
      q = @@mysql.query "SELECT COUNT(id) AS c FROM comments WHERE drop_id = \"#{id}\""
      comment_c = q.fetch_hash['c'].to_i
      q.free
      
      q = @@mysql.query "SELECT COUNT(id) AS c, AVG(rate) AS r FROM rates WHERE drop_id = \"#{id}\""
      h = q.fetch_hash
      rate_c = h['c'].to_i
      rate_r = h['r'].to_f
      q.free
      
      @@mysql.query "UPDATE drops SET sk_comment_count = #{comment_c}, sk_rate_count = #{rate_c}, sk_rate_avg = #{rate_r} WHERE id = \"#{id}\""
    end
    
    def self.fetch_comments(id)
      q = @@mysql.query "SELECT * FROM comments WHERE drop_id = \"#{id}\""
      comments = []; while h = q.fetch_hash; comments << h; end
      q.free
      
      return comments
    end
    
    def self.cmd_cl_info
      id = @@mysql.escape_string(data)
      
      q = @@mysql.query "SELECT * FROM drops WHERE id = \"#{id}\""
      drop = q.fetch_hash
      q.free
      
      comments = fetch_comments id
      
      if drop == nil
        notify "Unknown drop."
      else
        type = 'outgoing'
        
        r = "%.1f" % drop['sk_rate_avg'].to_f
        r = "+#{r}" unless r[0] == ?-
        
        f = "Found: " + (Time.new - Time.new.to_i + drop['date_found'].to_i).strftime("%d/%m/%Y %H:%m:%S")
        str  = "http://cl.ly/#{drop['id']} (#{drop['filename']}) - #{f} - #{drop['direct_url']}\n"
        str += "  #{drop['sk_comment_count']} comments, rated #{r} by #{drop['sk_rate_count']} votes\n"
        
        comments.each do |comment|
          d = (Time.new - Time.new.to_i + comment['time'].to_i).strftime("%d/%m/%Y %H:%m:%S")
          str += "\n  [#{comment['id']}] #{comment['handle']} on #{d}\n  #{comment['comment']}"
        end
        notify str
      end
    end
    
    def self.cmd_cl_comments(msg, data)
      notify "Alex must implement this." # TODO
    end
  end
end

CloudPlugin::Plugin.init_mysql