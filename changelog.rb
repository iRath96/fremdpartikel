# You're supposed to execute this...
# An xterm-256color terminal is recommended (for extra rainbows).
# ANSI colors are required!

def changelog
  version 0.9
  
  date 2013, 12, 9
  feature "Introduced this changelog." # Woo.
  comment "\1(cloc)\0 Fremdpartikel has 70 files, 1053 blank lines, 246 comments, 3927 lines of code"
  feature "\1Terminator.load_per_user\0 to monitor load for each user."
  bug_fix "Terminator would not notice threads that ended while RubyProf was running. " +
          "Also it would be unfair at killing processes (killing highest self_time process, not user with highest self_time)"
  feature "module \1NumericUtils\0 (included by Fixnum and Float) provides percent_s, p_of_s, time_s and size_s to cast numbers into meaningful strings."
  feature "Migrating Fremdpartikel's source and Plugins to NumericUtils."
  comment "FPPipe and FPProcess were moved into a module and are called FP::Pipe and FP::Process now."
  comment "AliasPlugin (esp. @env) and TrafficControl are \1deprecated\0! " +
          "Please stay away from using them, as they will be removed in the next version."
  thought "I don't think the changelog is colorful enough. It needs xterm-256color and maybe skins selectable by the user!"
  feature "module \1Persistence\0 (used by Ident-Management), include this module after setting default values for class_variables. " + 
          "(it will serialize class_variables on exit and restore them in include)"
  feature "Changelog is now xterm-256color, scheme based on 'Codeschool´ for vim. Also, it now wraps depending on your TermInfo.screen_size."
  thought "I probably could automatically rewrite the screen-content when the TermInfo.screen_size changes, but erm, who needs that? :P"
  
  date 2013, 12, 10
  
  feature "Introduced String#yes? and String#no? to quickly distinguish if an answer is affirmative or not."
  feature "Introduced 'interfaces´ for abstraction of different protocols."
  feature "Introduced \1Identity\0 as well as \1Authentication\0-Methods for users to be able to identify and be trusted."
  feature "Adapted the Skype-bridge to the new interfaces."
  comment "The \1User\0-class is considered as a kind of session. It also stores the identity when logged in."
  feature "Added an \1AuthPlugin\0 to be able to login and logout, as well as registering new accounts."
  feature "Added Identity-Ranks (guest, user, moderator, admin) and auto-login for AccountAuthentication."
  bug_fix "Fixed a bug in \1time_s\0 which returned arbitrary values for minutes and hours in certain cirumstances."
  comment "There should be Processes (or atleast pseudo-processes) for hooks (callbacks). Otherwise everything is totally messed up!"
  
  date 2013, 12, 12
  
  #
  # 
  #
  
  new_line
  version 0.93
  
  comment "\1TrafficControl\0 has been removed, \1AliasPlugin\0 remains existant but deprecated."
  feature "There is support for \1IRC\0 now (thanks to Cinch). Most commands and functionality like logging in already works."
  
  date 2013, 12, 14
  
  comment "Haven't had a lot of time to work on this project recently..."
  feature "\1Persistence\0 does backups for you now. It auto-saves every 60 seconds to avoid data-loss on crashes."
  feature "Introduced \1HashResponder\0 which wraps a hash and will respond to methods that exists as key in the hash and return the corresponding value."
  feature "Introduced Fremdpartikel::protocol and Protocol.shorten? which help commands decide how to format their output (shorten? is true for IRCProtocol)."
  feature "Started porting commands for efficient use with IRC."
  feature "PluginCommand now keeps track of the total invoke_count, of course using the Persistence API."
  
  date 2013, 12, 15
  
  feature "\1PasswordAuthentication\0 is now supported by the AuthPlugin and supports secure login (using session-based salts)."
  feature "The \1Dispatcher\0-class was rewritten and is 50% smaller now with the same functionality (and it's still easy to read)."
end

#
# The end.
#

require 'terminfo'
$width = TermInfo.screen_size[1]

# Thanks for your awesome Regexp, Lou! https://www.ruby-forum.com/topic/57805
def lb(text,width=$width-12)
  lines = text.scan(/\S.{0,#{width-2}}\S(?=\s|$)|\S+/)
  last_line = lines.pop
  ((lines.map do |l|
    raw = l.gsub("\0", '').gsub("\1", '')
    bare_length = raw.gsub(' ', '').length
    space_count = raw.length - bare_length
    space = width - bare_length
    l.gsub(' ') { |i| c = (space.to_f / space_count).ceil; space -= c; space_count -= 1; ' ' * c }
  end + [last_line]) * "\n").gsub("\0", "\033[0m").gsub("\1", "\033[1m")
end

def version(v); puts "= \033[38;5;153mVERSION #{'%.2f' % v}\033[0m ===="; end
def date(y,m,d); puts "\033[0;90m  (#{'%04d-%02d-%02d' % [y,m,d]})\033[0m"; end
def feature(t); puts "\033[38;5;180mo feature\033[0m  " + lb(t).gsub("\n", "\n           "); end
#def todo(id,t); puts "\033[38;5;153mo todo   \033[0m  \033[0;90m:#{id}\033[0m " + lb(t).gsub("\n", "\n           "); end
def comment(t);  puts "\033[38;5;68mo comment\033[0m  " + lb(t).gsub("\n", "\n           "); end
def thought(t); puts "\033[38;5;107mo thought\033[0m  " + lb(t).gsub("\n", "\n           "); end
def bug_fix(t); puts "\033[38;5;186mo bug-fix\033[0m  " + lb(t).gsub("\n", "\n           "); end
def new_line; puts; end

changelog # Show it!