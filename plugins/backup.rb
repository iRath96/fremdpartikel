module BackupPlugin
  class Plugin < PluginBase
    init_v2 :backup
    
    meta :name => "Backup Plugin",
         :author => "Alexander Rath",
         :version => 0.7,
         :description => "A plugin that deals with making backups of Fremdpartikel's data."
    
    cmd:perform_backup, "Perform a backup NOW.", :rank => :admin
    cmd:backups?, "Get a list of recent backups."
    
    # TODO: This needs to be implemented
  end
end