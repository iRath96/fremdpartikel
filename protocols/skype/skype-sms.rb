class SkypeSMS
  include SkypeObject
  
  api :sms, 'SMS'
  
  str :body, :reply_to_number
  str :target_numbers, :target_status # TODO: Should be 'arr[sym] or arr[str]'
  sym :type, :status, :failurereason, :price_currency
  int :timestamp, :price, :price_precision
  
  bool :is_failed_unseen
end