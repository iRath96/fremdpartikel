class QuotaError < Exception
  attr_accessor :type, :user
  def initialize(t, u)
    @type = t
    @user = u
  end
end

class Quota
  @@quota = {}
  def self.register(type, score, **hash)
    user = (hash[:user] or API.process.owner)
    @@quota[type] = {} if @@quota[type] == nil
    @@quota[type][user] = 0 if @@quota[type][user] == nil
    
    invalid = @@quota[type][user] > 20
    @@quota[type][user] += score if @@quota[type][user] < 40
    return true unless invalid
    
    raise QuotaError.new(type, user) if hash[:mode] == nil or hash[:mode] == :raise
    return false if hash[:mode] == :bool
  end
  
  def self.update
    @@quota.each do |(type,quota)|
      quota.each do |(owner,score)|
        @@quota[type][owner] -= 5 if score >= 5
      end
    end
  end
end

Thread.new do
  while true
    Quota.update
    sleep 2
  end
end