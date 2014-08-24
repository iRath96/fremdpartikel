module DPDPlugin
  class String
    def sp
      gsub("\xC2\xA0", ' ').strip
    end
  end
  
  def track_nr(id)
    uri = URI.parse "http://tracking.dpd.de/cgi-bin/delistrack?typ=32&lang=de&pknr=#{id}&var=internalNewSearch&x=10&y=13"
    n = Nokogiri::HTML(open(uri))
    
    # if 'not found' exit
    
    tracks = []
    n.css('table#plcTable tr')[2 .. -1].each do |row|
      tds = row.css('td')
      
      track = {}
      
      track[:pknr]  = id
      track[:time]  = Time.parse tds[0].text.sp
      track[:depot], track[:location] = tds[1].text.sp.split(' ', 2)
      track[:state] = tds[2].text.sp
      track[:base]  = ' ' + tds[3].text.sp.gsub(' •  ', ' ') + ' '
      track[:tour]  = tds[4].text.sp
      track[:codes] = tds[5].children.find_all { |i| i.instance_of? Nokogiri::XML::Text }.map { |i| i.text.sp } * ','
      track[:found] = Time.now
      
      tracks << track
    end
    
    tracks
  end
  
  #
  # Plugin class
  #
  
  class Plugin < PluginBase
    init_v2 :dpd
    
    meta :name => "DPD Plugin",
         :author => "Alexander Rath",
         :version => 0.2,
         :description => "Allows tracking of DPD packets."
    
    cmd:track, "Track a DPD-packet.", "packet_nr" # "@track 012831337", 100
    
    @@tracks = []
    
    def self.cmd_track
      @@tracks << [ msg.from_handle, data, 0 ]
      SkypeUser.withId($skype, msg.from_handle).push "Tracking #{data}..."
    end
    
    def self.update_tracks
      begin
        @@tracks.each do |track|
          handle, pknr, state = track
          tracks = track_nr pknr
          count = tracks.count
          
          if count > state
            SkypeUser.withId($skype, handle).push(tracks.map { |t| t.inspect} * "\n\n")
            track[2] = count
          end
        end
      rescue => e
        puts e.inspect
      end
    end
  end
  
  Thread.new do
    while true
      DPDPlugin::Plugin.update_tracks
      sleep 300
    end
  end
end