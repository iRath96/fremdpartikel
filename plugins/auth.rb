module AuthPlugin # TODO: Default rank for plugins, default value for required protocol
  class Plugin < PluginBase
   init_v2 :auth
   
   meta :name => "Authentication Plugin",
        :author => "Alexander Rath",
        :version => 1.0,
        :description => "Allows users to identify and use the Fremdpartikel-services."
    
    cmd:status   , "Check your status.", :rank => :guest
    cmd:register , "Register for fremdpartikel.", "fp-username email", :rank => :guest
    cmd:login    , "Login to your fremdpartikel account.", "fp-username", :rank => :guest
    cmd:logout   , "Logout from your fremdpartikel account."
    cmd:link     , "Link another messenger-account to your fremdpartikel account.", "uid"
    cmd:links?   , "List all links to your fremdpartikel account." # TODO: Implement this
    cmd:rechts?  , ""
    cmd:password , "Set yourself a new password to be able to authenticate somewhere else."
    cmd:seclog   , "Secure login using random keys (not safe against MitM!).", :rank => :guest # TODO: Public-key cryptography? :D
    hide:rechts?
    
    def self.cmd_rechts?; notify "Now you are one very funny German ..."; end
    
    # TODO: unregister
    # TODO: auto-logout
    # TODO: links +xyz -abc (everywhere in FP!)
    # TODO: Password-logging with key-encryption
    
    def self.cmd_status
      notify msg.user.logged_in? ? "You are logged in as '#{msg.user.identity.username}´ as #{msg.user.rank}." : "You are not logged in."
    end
    
    def self.cmd_login
      return notify "You probably are Lorenzo, aren't you?" if data == nil or data.empty?
      username, password = data.split ' ', 2
      
      msg.user.logout! if msg.user.logged_in?
      
      ident = Identity.with_name username
      if ident
        if password == nil # No password supplied, identify by uid!
          ident.auths.each do |auth|
            if auth.is_a?(AccountAuthentication) and auth.valid?(msg.user.account)
              notify "You have been logged in as '#{username}´ as #{ident.rank}."
              msg.user.login ident
              return
            end
          end
          notify "Could not identify you by account (#{msg.user.account.uid})."
        else # Identify by password. TODO: Do some Quota-limiting here.
          ident.auths.each do |auth|
            if auth.is_a?(PasswordAuthentication) and auth.valid?(password)
              notify "You have been logged in as '#{username}´ as #{ident.rank}."
              msg.user.login ident
              return
            end
          end
          notify "Could not identify you by password."
        end
      else
        notify "No user named '#{data}´ found."
      end
    end
    
    def self.cmd_logout
      msg.user.logout!
      notify "You have been logged out."
    end
    
    def self.cmd_register
      unless msg.user.account
        notify "Registration only works for users with account at the moment."
        notify "If you're on IRC, identify with NickServ." # TODO: There should be a way of telling if this is IRC.
      end
      
      username, email = data.split ' '
      ident = Identity.register(username, email)
      
      unless ident
        field, error = Identity.register_error? username, email
        notify "Cannot register '#{username}´, invalid #{field} (#{error})."
        return
      end
      
      ident.allow_auth_by AccountAuthentication.new(msg.user.account)
      notify "You have successfully been registred!"
    end
    
    def self.cmd_link
      msg.user.identity.allow_auth_by AccountAuthentication.new(GenericAccount.new data)
      notify "The uid '#{data}´ has been allowed for your account."
    end
    
    def self.cmd_links?
      uids = msg.user.identity.auths.find_all { |auth| auth.is_a? AccountAuthentication }.map { |a| "'#{a.uid}´" }
      notify "Allowed uids for '#{msg.user.identity.username}´ are #{uids * ', '}."
    end
    
    def self.cmd_password
      msg.user.identity.auths.delete_if { |auth| auth.is_a? PasswordAuthentication }
      unless data == nil
        msg.user.identity.auths << PasswordAuthentication.new(data)
        notify "Your new password has been set."
      else
        notify "PasswordAuthentication has been disabled for your account."
      end
    end
    
    def self.cmd_seclog
      msg.user.session[:key] = rand(128**36).to_s 36 if msg.user.session[:key] == nil
      if data == nil
        notify "Your key is '#{msg.user.session[:key]}´, #{msg.user.name}."
        notify "Digest::MD5.hexdigest(your_key + Digest::MD5.hexdigest((('A'..'z').to_a + [your_password]) * ':')) is expected."
      else
        username, hash = data.split ' ', 2
        ident = Identity.with_name username
        if ident
          ident.auths.each do |auth|
            if auth.is_a?(PasswordAuthentication) and auth.valid?(hash, msg.user.session[:key])
              notify "You have been logged in as '#{username}´ as #{ident.rank}."
              msg.user.login ident
              return
            end
          end
          notify "Could not login you by password."
        else
          notify "Unknown user '#{username}´."
        end
      end
    end
  end
end