class AliasPlugin < PluginBase
  init :alias
  
  meta :name => "Alias Plugin",
       :author => "Alexander Rath",
       :version => 0.2,
       :description => "Create aliases for compound commands."
  
  cmd:alias, "Create an alias.", "aliasname regex code+"
  cmd:unalias, "Destroy an alias.", "alias_name"
  cmd:source, "Show the source of an alias.", "alias_name"
  cmd:acc, "Accumulator.", "command+"

  @@code = []
  @@acc = nil
  
  def self.cmd_acc(msg, data)
    bmsg = FakeMessage.new msg, FakeChat.new(msg.chat)
    
    thread = eval_cmd bmsg, data
    thread.join if thread
    
    @@acc = bmsg.chat.buffer.join "\n"
    #msg.chat.push "acc:" + bmsg.chat.buffer.inspect
  end
  
  def self.cmd_source(msg, data)
    ali = @@code.find_all { |i| i[:name] == data }.pop
    msg.chat.push "@source #{data} :-  #{(ali[:pattern].inspect + "\n" + ali[:code]) rescue '(no such command)'}"
  end
  
  def self.cmd_alias(msg, data)
    name, other = data.split(' ', 2)
    pattern, code = other.split("\n", 2)
    pattern = Regexp.new(pattern, 'i')
    
    ali = @@code.find_all { |i| i[:name] == name }
    if ali.length == 0 and PluginBase.has_command?(name)
      msg.chat.push "@alias :-  #{$CMD_SYMBOL+name} is already defined by #{PluginBase.commands[name.to_sym].defined_by.name}"
      return
    end
    
    ali = {
      :name => name,
      :code => code,
      :pattern => pattern,
      :created => [ msg.from_handle, Time.now ]
    }

    defcmd ali

    @@code << ali
    store
  end
  
  def self.cmd_unalias(msg, data)
    ali = @@code.find_all { |i| i[:name] == data }
    if ali.length == 0
      msg.chat.push "@unalias #{data} :-  (no such command)"
    else
      ali.each { |a| @@code.delete a }
      store
      
      unregister_cmd data
      msg.chat.push "@unalias #{data} :-  Command removed."
    end
  end

  def self.defcmd(ali)
    throw :potatoes if ali[:name].to_sym == :alias or ali[:name].to_sym == :source or ali[:name].to_sym == :unalias
    
    cmd ali[:name].to_sym, "(script by #{ali[:created][0]})", "Nobody knows what it's like to be BATMAN."

    self.define_singleton_method(('cmd_' + ali[:name].gsub('-', '_')).to_sym) do |m,d|
      #m.chat.push pattern.inspect
      #m.chat.push d.inspect
      args = d.match(ali[:pattern]).to_a rescue []
      ali[:code].split("\n").each do |line|
        line.gsub!(/\\(.)/) do
          next case $1
            when 'a' then @@acc
            when 'n' then "\n"
            when 'h' then m.from_handle
            when 'f' then m.from_name
            when 'c' then m.chat_name
            when 'm' then ali[:name]
            when 'p' then FP::Process.current.pid
            else args[$1.to_i]
          end
        end
        thread = eval_cmd m, line.lstrip, :with_rank => :user
        thread.join unless thread == nil
      end
    end
  end

  def self.store
    File.open("./data/alias", 'wb+') { |f| f.write Marshal::dump(@@code) }
  end

  def self.load
    @@code = (Marshal::load File.open("./data/alias", 'rb') { |f| f.read }).uniq { |ali| ali[:name] } rescue []
    @@code.each { |ali| begin; defcmd ali; rescue => e; end }
  end
end