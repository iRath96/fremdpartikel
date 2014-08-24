class PObject
  attr_accessor :uid, :vfs, :object
  def initialize(uid, default=nil, vfs=nil)
    @uid = uid
    @vfs = (vfs or API.vfs)
    @object = default
    
    refresh
    
    #ObjectSpace.define_finalizer self do
    #  save
    #end
  end
  
  def save
    f = __dir.mkfile @uid, ''
    f.write @object.to_json
    @vfs.save
  end
  def refresh
    dir = __dir
    unless __dir[@uid] == nil
      @object = JSON.parse __dir[@uid].read
    end
  end
  def delete!
    __dir.remove @uid
  end
  
  private
  def __dir; @vfs.root.mkdir 'persistence', false; end
end