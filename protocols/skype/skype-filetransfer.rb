class SkypeFileTransfer < Dispatcher
  include SkypeObject
  
  api :filetransfer, 'FILETRANSFER'
  
  key:error => :failurereason
  key:speed => :bytespersecond
  key:from_name => :partner_dispname
  key:from_handle => :partner_handle
  key:bytes_received => :bytestransfered
  key:failure_reason => :failurereason
  
  sym :type, :status, :failurereason
  str :partner_handle, :partner_dispname, :filepath, :filename, :filesize
  int :starttime, :finishtime, :bytespersecond, :bytestransfered
end