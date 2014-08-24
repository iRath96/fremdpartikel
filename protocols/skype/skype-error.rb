# TODO: Rough draft.

class SkypeError
  include SkypeObject
  
  api :chat, 'ERROR'
  
  int :id
  str :msg
end