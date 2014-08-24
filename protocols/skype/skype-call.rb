class SkypeCall # TODO: Experimental!
  include SkypeObject
  
  api :call, 'CALL'
  
  def self.api_name; "CALL"; end
  def self.sym_name; :call; end
end