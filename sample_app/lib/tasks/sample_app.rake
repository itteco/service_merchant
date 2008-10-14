namespace :sample_app do
  desc "Create subscription management and require plugins' database tables"
  task :setup => %w(dependencies tracker:create_tables subscription:create_tables)

  task :dependencies => :environment do
    require 'tracker/tasks/schema' # TRACKER db
    require 'subscription_management/tasks/schema' # SM db
  end
end
