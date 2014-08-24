module ExamplePlugin
  class Plugin < PluginBase
    init_v2 :example
    
    meta :name => "Example Plugin",
         :author => "Alexander Rath",
         :version => 4.2,
         :description => "This is an example plugin."
    
    cmd:'example-command', "This is the description.", "@example-command An example"
    
    def self.cmd_example_command
      notify "Your argument: #{data}"
    end
  end
end