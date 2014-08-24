#encoding=utf-8

require 'open-uri'
require 'json'

WEATHER_KEY = "204df492f224d7c8"

module WeatherPlugin  
  class WeatherPlugin < PluginBase
    init_v2 :weather
    
    meta :name => "Weather Plugin",
         :author => "Paul Clement Côté",
         :version => 1.2,
         :description => "Quickly retrieve weather information for your area!"
    
    cmd :weather, "Find the weather for your city.", "Knoxville, TN"
    
    def self.cmd_weather
      city = data
      *city, initials = city.gsub(',', '').split ' '
      city = city.join ' '
      
      begin
        cwq = "http://api.wunderground.com/api/#{WEATHER_KEY}/conditions/q/#{initials}/#{city}.json"
        query = open(cwq)
        qr = JSON.parse query.read
        
        temp_f = qr['current_observation']['temp_f']
        temp_c = qr['current_observation']['temp_c']
        weather = qr['current_observation']['weather']
        city = qr['current_observation']['display_location']['city']
        full = qr['current_observation']['display_location']['full']
        
        notify "The temperature in #{city} is #{temp_f}°F / #{temp_c}°C\nCurrent conditions are: #{weather}"
      rescue => e
        puts e.inspect
        puts e.backtrace.inspect
        
        notify "'#{city}´ (in '#{initials}´) does not exist."
      end
    end
  end
end