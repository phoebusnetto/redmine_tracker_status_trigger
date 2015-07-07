Redmine::Plugin.register :redmine_tracker_status_trigger do
  name 'Redmine Tracker Status Trigger plugin'
  author 'José Cavalcanti de Moura Netto'
  description 'This plugin is used to auto-change issue status depending on the relation of it with it Children/Parents Issues or Related Issues.'
  version '0.0.2'
  url 'http://www.phoebus.com.br'
  author_url 'http://www.phoebus.com.br'
  
  settings :default => { :empty => true}, :partial => 'settings/settings'
end

require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    require 'tracker_status_trigger'
    Issue.send(:include, TrackerStatusTrigger::Patches::IssuePatch)
  end
end
