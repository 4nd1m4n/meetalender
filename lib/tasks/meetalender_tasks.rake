namespace :meetups do
  desc 'Syncronize selected meetup groups events with the configured google calendar.'
  task :syncronize => :environment do
    require 'meetups_calendar_syncer'
    MeetupsCalendarSyncer.sync_meetups_to_calendar(MeetupsCalendarSyncer.gather_meetups())
  end
end