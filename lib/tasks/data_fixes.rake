require 'chf/data_fixes/util'
require 'chf/data_fixes/work_dates'
require 'chf/data_fixes/add_catlu_access'
require 'chf/data_fixes/strip_strings'

namespace :chf do
  # Most of these are anticipated to be one-time fixes, may get removed
  # from rake later?
  namespace :data_fix do

    desc "test"
    task :test => :environment do
      raise "Error!"
    end

    desc "Execute a rake task wrapped in maintenance enable/disable"
    task :rake_with_maintenance do
      if ENV['TASK']
        SSHKit.config.output.info("Turning on maintenance mode")
        invoke("maintenance:enable")

        tasks = ENV['TASK'].split(',')

        on roles(:app) do
          within current_path do
            with rails_env: fetch(:rails_env) do
              tasks.each do |task|
                execute :rake, task, interaction_handler: StreamOutputInteractionHandler.new(:stderr)
                SSHKit.config.output.info("finished rake #{task}")
              end
            end
          end
        end

        SSHKit.config.output.info("Turning off maintenance mode")
        invoke("maintenance:disable")
      else
        puts "\n\nFailed! You need to specify the 'TASK' parameter!",
             "Usage: cap <stage> invoke:rake TASK=your:task"
      end
    end


    desc "Bulk fix a variety of things"
    task :bulk_fix => :environment do
      # Apply a variety of fixes in one pass, to go quicker.
      # what fixes are included may change from time to time,
      # most of these are run-once things.
      CHF::DataFixes::Util.update_works do |w|
        [
          CHF::DataFixes::WorkDates.new(w).change,
          CHF::DataFixes::AddCatluAccess.new(w).change,
          CHF::DataFixes::StripStrings.new(w).change,
          CHF::DataFixes::LibraryDivisionChange.new(w).change
        ].any?
      end
    end

    desc "Fix Work dates to be Dates"
    task :fix_work_dates => :environment do
      CHF::DataFixes::Util.update_works do |w|
        CHF::DataFixes::WorkDates.new(w).change
      end
    end

    desc "Add clu@chemheritage.org to all edit_users"
    task :add_catlu_access => :environment do
      CHF::DataFixes::Util.update_works do |w|
        CHF::DataFixes::AddCatluAccess.new(w).change
      end
    end

    desc "Strip lead/trail spaces from properties"
    task :strip_spaces => :environment do
      CHF::DataFixes::Util.update_works do |w|
        CHF::DataFixes::StripStrings.new(w).change
      end
    end

    desc "'Othmer...' to 'Library' in division"
    task :library_division => :environment do
      CHF::DataFixes::Util.update_works do |w|
        CHF::DataFixes::LibraryDivisionChange.new(w).change
      end
    end
  end
end


