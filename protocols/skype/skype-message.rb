class SkypeMessage < Dispatcher
  include SkypeObject
  
  api :message, [ 'CHATMESSAGE', 'MESSAGE' ]
  numeric_ids
  
  key:content => :body
  key:reason  => :leavereason
  key:chat_id => :chatname
  key:editable? => :is_editable
  key:chat_name => :chatname
  key:from_name => :from_dispname
  key:chat_handle => :chatname
  key:sender_name => :from_dispname
  key:sender_handle => :from_handle
  key:edited_handle => :edited_by
  key:leave_reason  => :leavereason
  
=begin
  def self.transform_value(key, value)
    return case key
      when :from_handle, :chatname, :edited_by then value.downcase
      when :type, :status then value.downcase.to_sym
      when :users then value.downcase.split(', ')
      when :edited_timestamp, :options then value.to_i
      else value
    end
  end
=end
  
  str :from_handle, :from_dispname, :chatname, :body
  str :edited_by, :role, :users # TODO: should be 'arr'
  sym :type, :status, :leavereason
  int :timestamp, :options, :edited_timestamp
  bool :is_editable, :seen
    
  attr_accessor :is_new, :is_local
  attr_accessor :chat
  
  def initialize(skype, id)
    super
    
    @is_new = 2
    @is_local = false
    
    @status = :unknown
  end
  
  def sender; SkypeUser.withId @skype, @from_handle; end
  def chat; SkypeChat.withId @skype, @chatname; end
  alias_method :user, :sender
  
  def inform_change(key, value)
    case key
      when :status
        @is_local = true if @status == :sent || @status == :sending
        @is_new = @is_new - 1 if @is_new
    end
  end
  
  def is_new?; @is_new > 0; end
  def is_local?; @is_local; end
end