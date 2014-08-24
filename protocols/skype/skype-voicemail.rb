=begin
class SkypeVoicemail
  include SkypeObject
  
  api :filetransfer, 'VOICEMAIL'
  
  key:error => :failurereason
  key:from_name => :partner_dispname
  key:from_handle => :partner_handle
  key:failure_reason => :failurereason
  
  sym :type, :status, :failurereason
  str :partner_handle, :partner_dispname
  str :subject # Not used
  int :timestamp, :duration, :allowed_duration
  
  str :input, :output, :capture_mic # TODO: ??
end
=end