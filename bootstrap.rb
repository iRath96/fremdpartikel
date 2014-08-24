[
  'dispatcher', 'persistence', 'identity',
  'api', 'terminator', 'vfs', 'quota',
  'process', 'plugin', 'pobject'
].each { |f| require "./classes/#{f}.rb" }
Dir['./protocols/*'].each { |protocol| require "#{protocol}/bootstrap.rb" }