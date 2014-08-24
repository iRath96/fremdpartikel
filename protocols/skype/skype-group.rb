class SkypeGroup < Dispatcher
  include SkypeObject
  
  api :group, 'GROUP'
  
  key:count => :nrofusers
  key:online_count => :nrofusers_online
  
  str :displayname, :users
  sym :type
  int :nrofusers, :nrofusers_online, :custom_group_id
end