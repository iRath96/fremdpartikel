class SkypeProfile < Dispatcher
  include SkypeObject
  
  api :profile, 'PROFILE'
  singleton
  
  key:mood => :mood_text
  
  int :pstn_balance, :birthday, :timezone
  sym :pstn_balance_currency, :sex
  sym :country, :ipcountry # TODO: Or str?
  str :fullname, :province, :city, :phone_home, :phone_office, :phone_mobile
  str :homepage, :about, :mood_text, :rich_mood_text
  str :languages # TODO: Should be 'arr'
  
  # TODO: Unsure:
  
  str :call_forward_rules
  int :call_noanswer_timeout
  bool :call_apply_cf, :call_send_to_vm
  int :sms_validated_numbers # TODO: Should be 'arr'
end