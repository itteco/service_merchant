namespace :sample_app do
  # Prevent visibility outside sample_app dir
  #if %r(^#{Dir.getwd}) =~ __FILE__ and %r(/sample_app/$) =~ Dir.getwd
  if Dir.getwd =~ /sample_app/
    desc "Create subscription management and require plugins' database tables"
    task :setup => %w(dependencies tracker:create_tables subscription:create_tables)

    task :dependencies => :environment do
      require 'tracker/tasks/schema' # TRACKER db
      require 'subscription_management/tasks/schema' # SM db
    end
  end
end
