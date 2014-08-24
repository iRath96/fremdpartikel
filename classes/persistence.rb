# TODO: Delete unused files?
$p9ec = []
module Persistence
  def self.p9ec_fn(k)
    "./data/persistence/#{k.name.gsub('::', '.').gsub(/[^a-z0-9\.]/i, '')}"
  end
  
  def self.included(k)
    k.extend ClassMethods
    $p9ec << [ k, k.class_variables, false ]
    File.open(p9ec_fn(k), 'rb') { |f| Marshal.load f }.each{ |z,v| k.class_variable_set z, v } if File.exists?p9ec_fn(k)
  end
  
  def self.backup
    $p9ec.each do |(k, v, meths)|
      begin
        File.open(p9ec_fn(k), 'wb+') do |f|
          f.write Marshal.dump(v.inject({}) do |h,z|
            h[z] = meths ? k.method(z[2..-1].to_sym).call : k.class_variable_get(z)
            h
          end)
        end
      rescue => e
        puts "[Persistence] Attention: Could not store #{k.inspect}."
        puts "v=#{v.inspect}, meths=#{meths.inspect}"
        puts e.inspect
        puts e.backtrace.inspect
        puts "(continuing)"
      end
    end
  end
  
  module ClassMethods
    def use_methods(u=true)
      $p9ec.find { |(k)| k == self }[2] = u
    end
  end
  
  at_exit do
    backup
  end
end

Thread.new do
  while true
    sleep 30
    Persistence.backup
  end
end