class SkypeMember
  include SkypeObject
  
  api :member, 'CHATMEMBER'
  
  key:handle => :identity
  key:active? => :is_active
  key:chat_id => :chatname
  key:chat_name => :chatname
  key:chat_handle => :chatname
  
  str :chatname, :identity
  sym :role
  bool :is_active
end