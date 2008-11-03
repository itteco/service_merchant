require File.dirname(__FILE__)+'/../tracker/tasks/schema'
require File.dirname(__FILE__)+'/../subscription_management/tasks/schema'

namespace :service_merchant do
  desc "Create all tables"
  task :create_all_tables => ["tracker:create_tables", "subscription:create_tables"]

  desc "Drop all tables"
  task :drop_all_tables => ["subscription:drop_tables", "tracker:drop_tables"]
end
