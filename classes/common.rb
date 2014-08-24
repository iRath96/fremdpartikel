$ranks = [ :banned, :guest, :user, :moderator, :admin, :root ]
class Symbol
  def <=>(o)
    $ranks.index(self) <=> $ranks.index(o)
  end
end

class Class
  def subclasses; s = []; ObjectSpace.each_object(Module) { |m| s << m if m.ancestors.include? self }; s; end
end

class String
  def yes?; match(/^(y$|yes|yeah)/i)!=nil; end
  def no?; !yes?; end
  def cmd?; self[0...$CMD_SYMBOL.length] == $CMD_SYMBOL; end
end

class Hash
  def +(o); merge o; end
end

module NumericUtils # For casting numbers to 'meaningful´ strings
  def percent_s(precision=2); "%.#{precision}f%%" % (100 * self); end
  def p_of_s(whole, precision=2); "%.#{precision}f%%" % (100.0 * self / whole); end
  def time_s
    days = self.to_i / 86400
    t = Time.at(self - 86400 * days).utc
    
    # TODO: This is inefficient!
    # TODO: Is it?
    
    str = t.strftime "%Ss"
    str = t.strftime "%Mmin %Ss" if self >= 60
    str = t.strftime "%Hh %Mmin %Ss" if self >= 3600
    
    days > 0 ? "#{days}d #{str}" : "#{str}"
  end
  def size_s
    units = [ '', 'Ki', 'Mi', 'Gi', 'Ti', 'Pi' ]

    val = self
    index = 0
    
    while (val > 1023) && (index < units.length)
      val /= 1024.0
      index += 1
    end
    
    (index == 0 ? "%.2f" % val : "%.2f" % val + units[index]) + 'B'
  end
end

class Fixnum; include NumericUtils; end
class Float;  include NumericUtils; end