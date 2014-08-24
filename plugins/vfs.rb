puts "TODO: Write an sshd for fremdpartikel."

module VFSPlugin
  class Plugin < PluginBase
    init_v2 :vfs
    
    meta :name => "VFS Plugin",
         :author => "Alexander Rath",
         :version => 0.9,
         :description => "Helps managing virtual file-systems."
    
    cmd:lsfs, "List the files in a file-system.", "name"
    cmd:listfs, "List all file-systems."
    
    def self.cmd_listfs
      all = data == nil
      count = { :real => 0, :disk => 0, :entries => [] }
      
      {
        :user => 'data/vfs/*.vfs',
        :plugin => 'data/vfs-ext/*.vfs'
      }.each do |(type,path)|
        Dir[path].each { |path| fsinfo path, "(#{type}) ", count if all or path.split('/').pop == "#{data}.vfs" }
      end
      
      if protocol.shorten?
        notify count[:entries].map { |e|
          "#{e[:prefix]}#{e[:path]} (#{e[:quota_size]}, #{e[:quota]} of #{e[:max_quota_size]} | #{e[:params]})"
        } * ", "
      else
        notify count[:entries].map { |e|
          "#{e[:prefix]}#{e[:path]}, #{e[:params]} - #{e[:quota_size]}/#{e[:max_quota_size]} (#{e[:quota]}) — #{e[:hd_size]} on HD."
        } * "\n"
        notify "— #{count[:real].size_s} of data, using #{count[:disk].size_s} on space on Alex's HD."
      end
    end
    
    def self.cmd_lsfs
      path = ''
      {
        :user => 'data/vfs/*.vfs',
        :plugin => 'data/vfs-ext/*.vfs'
      }.each do |(type,pt)|
        Dir[pt].each { |pt| path = pt if pt.split('/').pop == "#{data}.vfs" }
      end
      
      if path
        notify fs_tree('/', VFS::VFS.new(path).root)
      else
        notify "#{data} could not be found."
      end
    end
    
    def self.fsinfo(path, prefix='', count={})
      vfs = VFS::VFS.new path
      params = vfs.get_params
      
      pstring = params[:read] == :public ? 'Public-Read' : 'Private'
      pstring = 'Public-R/W' if params[:write] == :public
      
      quota = vfs.quota
      
      #hd = "#{vfs.store_size.size_s} on HD"
      #notify "#{prefix}#{path}  [ #{quota.p_of_s $MAX_QUOTA} | #{quota.size_s} of #{$MAX_QUOTA.size_s} — #{hd} ], #{pstring}" +
      #  (short ? '' : (vfs.root == nil ? '(broken)' : "\n" + fs_tree('/', vfs.root)))
      
      count[:disk] += vfs.store_size
      count[:real] += vfs.quota
      count[:entries] << {
        :prefix => prefix,
        :path => path,
        :hd => vfs.store_size.size_s,
        :quota => quota.p_of_s($MAX_QUOTA),
        :quota_size => quota.size_s,
        :max_quota_size => $MAX_QUOTA.size_s,
        :hd_size => vfs.store_size.size_s,
        :params => pstring
      }
    end
    
  private
    
    def self.fs_tree(name, node, prefix='')
      #pre = prefix + ' ' * (1.85 * (10 - prefix.length))
      pre = prefix
      
      return "?" if node == nil
      return "#{'%04d' % node.id} #{pre}  #{'%-20s' % name} #{node.size.size_s}" if node.is_a? VFS::FileNode
      return "#{'%04d' % node.id} #{pre}  #{'%-20s' % name}\n" +
        node.entries.map { |name| fs_tree("#{name}".force_encoding('utf-8'), node[name], prefix + '–') }.join("\n")
    end
  end
end