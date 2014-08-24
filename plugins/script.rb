module ScriptPlugin
  class Plugin < PluginBase
   init_v2 :script
   
   meta :name => "Script Plugin",
        :author => "Alexander Rath",
        :version => 1.0,
        :description => "Provides basic functionality to work with in scripts."
    
    cmd:'+', "Addition.", "number number"
    cmd:'-', "Subtraction.", "number number"
    cmd:'*', "Multiplication.", "number number"
    cmd:'/', "Division.", "number number"
    
    '+-/*'.chars.each do |op|
      define_singleton_method('cmd_'+(op=='-'?'_':op)) { push data.split(' ').map(&:to_f).reduce(&op.to_sym).to_s }
    end
    
    cmd:rand, "Get a random number.", "number"
    
    def self.cmd_rand
      push rand(data.to_i).to_s
    end
    
    cmd:concat, "Concatenation.", "string string"
    
    def self.cmd_concat
      push data.split(' ').join('')
    end
    
    cmd:floor, "Floor a number.", "number"
    
    def self.cmd_floor
      push data.to_i.to_s
    end
    
    cmd:'=', "Result of something.", "@= 2"
    define_singleton_method('cmd_=') { push data }
    
    cmd:'inspect', "Inspect / escape a string.", "string"
    def self.cmd_inspect
      push data.inspect
    end
    
    cmd:'if', "Do a branch based on a variable.", "env_name command+"
    def self.cmd_if
      var, d = data.split ' ', 2
      value = FP::Process.current.get_env_var var
      return if value == '0' or value.strip == ''
      
      if d[0...$CMD_SYMBOL.length] == $CMD_SYMBOL
        cmd, data = d.split(' ', 2)
        func = PluginBase[cmd[1 .. -1].downcase.to_sym]
        
        if func == nil
          msg.chat.push "@if #{data} :-  Unknown command."
        else
          thread = eval_cmd msg, d
          thread.join unless thread == nil
        end
      else
        msg.chat.push "@if #{data} :-  Done!"
      end
    end
    
    cmd:sleep, "Sleep for a certain duration (in seconds).", "number"
    def self.cmd_sleep; sleep data.to_i; end
  end
end