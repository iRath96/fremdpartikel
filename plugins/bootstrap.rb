Dir.entries('./plugins/').find_all { |s| s.match /\.rb$/i }.each do |f|
  require './plugins/' + f unless f == $0
end