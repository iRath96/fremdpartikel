require 'zlib'

$MAX_QUOTA = 1024 * 1024 * 100

module VFS
  ROOT_NODE = 0
  
  FOLDER_FLAG = 0x01
  PUBLIC_READ = 0x02
  PUBLIC_WRITE = 0x04
  
  NO_INHERIT = 0x10 # Use own flags instead of root flags.
  
  #
  # Nodes.
  #
  
  def self.fe(s); s.force_encoding('ascii-8bit'); end
  
  class Node
    attr_accessor :vfs, :id, :flags, :content
    def initialize(v,i,f,c)
      @vfs = v
      
      @id = i
      @flags = f
      @content = VFS::fe c
    end
    
    def serialize
      [ @id, @flags, @content.length ].pack('N3') + @content
    end
    
    def inspect; "<Node:#{@id}>"; end
  end
  
  class FileNode < Node
    def initialize(v,i,f,c)
      super
    end
    
    def inspect; "<FileNode:#{@id}>"; end
    
    def read; @content; end
    def append(c); @content += VFS::fe c; end
    def write(c); @content = VFS::fe c; end
    def clear(c); @content = VFS::fe ''; end
    def size; @content.length; end
  end
  
  class FolderNode < Node
    def initialize(v,i,f,c)
      super
      
      @files = {}
      
      c = @content
      i = 0
      
      while i < c.length
        id, flags, length = c[i...i+=10].unpack 'N2n'
        filename = c[i...i+=length]
        
        @vfs.link id # Notify the VFS that the node with `id` is used.
        @files[filename] = { :id => id, :flags => flags }
      end
    end
    
    def inspect; "<FolderNode:#{@id},#{@files.map { |k,v| "#{k}(#{v[:id]})" }.inspect}>"; end
    def entries; @files.keys; end
    
    def serialize
      @content = @files.reduce(VFS::fe '') do |r,(name,v)|
        next r if @vfs.nodes[v[:id]] == nil
        r + VFS::fe([ v[:id], v[:flags], name.length ].pack('N2n') + name)
      end
      
      super
    end
    
    def [](name)
      @vfs.nodes[@files[name][:id]] rescue nil
    end
    
    def []=(name, node)
      remove name # To inform the VFS about the change.
      
      @vfs.link node.id # Notify the VFS that the node with `id` is used.
      @files[name] = { :id => node.id, :flags => 0 }
    end
    
    def mkfile(name, content, overwrite=true)
      return if self[name] != nil and !overwrite
      remove name
      self[name] = @vfs.create_file content
    end
    
    def mkdir(name, overwrite=true)
      return self[name] if self[name] != nil and !overwrite
      
      remove name
      self[name] = @vfs.create_dir
    end
    
    def remove(name)
      @vfs.unlink @files[name][:id] unless @files[name] == nil
      @files.delete name
    end
    
    def clear
      @files.each do |(name,v)|
        @vfs.unlink v[:id]
      end
      
      @files = {}
    end
  end
  
  #
  # The VFS.
  #
  
  class VFS
    attr_accessor :nodes, :store_path
    attr_reader :store_size
    
    def self.fe(s); s.force_encoding('ascii-8bit'); end
    
    def initialize(store_path, owner=false)
      @owner = owner
      
      @store_path = store_path
      @last_id = 0
      
      @linked = Hash.new 0
      @linked[0] += 1
      
      c = File.open(store_path, 'rb') { |f| @store_size = (c = f.read).length; Zlib::Inflate.inflate c } rescue VFS::fe('')
      @nodes = {}
      
      i = 0
      while i < c.length
        id, flags, length = c[i...i+=12].unpack 'N3'
        content = c[i...i+=length]
        
        @nodes[id] = (flags & 0x01 == 1 ? FolderNode : FileNode).new self, id, flags, content
        
        @last_id = id if id > @last_id
      end
    end
    
    def link(id); @linked[id] += 1; end
    def unlink(id); @linked[id] -= 1; end
    def linked?(id); @linked[id] > 0; end
    
    def set_params(**params)
      return false unless @owner
      
      root.flags  = FOLDER_FLAG
      root.flags |= PUBLIC_READ if params[:read] and params[:read] == :public
      root.flags |= PUBLIC_WRITE if params[:write] and params[:write] == :public
      
      save
    end
    
    def get_params
      params = {}
      params[:read] = :public if root.flags & PUBLIC_READ != 0
      params[:write] = :public if root.flags & PUBLIC_WRITE != 0 # TODO: Security bug. People could just override root.flags
      params
    end
    
    def format
      @nodes = {}
      @nodes[0] = FolderNode.new self, ROOT_NODE, FOLDER_FLAG, ''
      
      @linked = Hash.new 0
      @linked[0] += 1
    end
    
    def serialize
      @nodes.reduce(VFS::fe '') do |r,(id,node)|
        unless linked? id
          #puts "Removing #{id}, no reference."
        end
        
        next r unless linked? id
        r + VFS::fe(node.serialize)
      end
    end
    
    def save
      return false unless @owner or (root.flags & PUBLIC_WRITE != 0)
      return false if quota > $MAX_QUOTA
      File.open(store_path, 'wb+') { |f| @store_siez = f.write(Zlib::Deflate.deflate(self.serialize)) }
      return true
    end
    
    def root; @nodes[0]; end
    
    def create_file(content)
      id = @last_id += 1
      @nodes[id] = FileNode.new self, id, 0, content
    end
    
    def create_dir
      id = @last_id += 1
      @nodes[id] = FolderNode.new self, id, FOLDER_FLAG, ''
    end
    
    def [](path); traverse path; end
    
    def traverse(path)
      begin
        node = root
        (path.split('/')[1..-1] or []).each { |name| node = node[name] }
        return node
      rescue => e
        puts e.inspect
        return nil
      end
    end
    
    def read(path)
      node = traverse(path)
      return nil if node == nil
      return node.content
    end
    
    def remove(path)
      path = path.split('/')
      name = path.pop
      
      parent = traverse(path.join('/'))
      return false if parent[name] == nil
      parent.remove name
    end
    
    def quota(mode=:all)
      return serialize.length if mode == :real
      return Zlib::Deflate.deflate(serialize).length if mode == :disk
      
      @nodes.reduce(0) do |r,(id,node)|
        next r if node.is_a?(FileNode) and mode == :folder
        next r if node.is_a?(FolderNode) and mode == :file
        next r + node.content.size
      end
    end
  end
end

#
# Test
#

=begin
include VFS

v = VFS::VFS.new 'test.vfs'

v.format

v.root.mkfile 'dance.txt', 'This is madness.'
v.root.mkdir 'cake'
v.root['cake'].mkfile 'index.html', '<html>Is this a file?</html>'

puts v.read '/cake/index.html'

v.save
=end