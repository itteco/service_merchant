namespace :subscription do
  desc 'Create Subscription management database tables'
  task :create_tables => :connection do
    ActiveRecord::Base.connection.create_table :subscriptions, :force => true do |t|
      t.column :account_id,                 :string, :null => false
      t.column :tariff_plan_id,             :string, :null => false
      t.column :taxes_id,                   :string, :null => false
      t.column :quantity,                   :integer, :null => false
      t.column :currency,                   :string, :null => false
      t.column :net_amount,                 :integer, :null => false
      t.column :taxes_amount,               :integer, :null => false
      t.column :periodicity,                :string, :null => false
      t.column :starts_on,                  :date,   :null => false
      t.column :ends_on,                    :date
      t.column :status,                     :string, :null => false
      t.column :created_at,                 :datetime, :null => false
      t.column :updated_at,                 :datetime
      t.column :deleted_at,                 :datetime
    end
    ActiveRecord::Base.connection.add_index :subscriptions, [ :account_id ], :name => 'ix_subscription_account'

    ActiveRecord::Base.connection.create_table :subscription_profiles, :force => true do |t|
      t.column :subscription_id, :integer,      :null => false
      t.column :recurring_payment_profile_id, :integer, :null => false
      t.column :created_at,                 :datetime, :null => false
    end
    ActiveRecord::Base.connection.add_index :subscription_profiles, [ :subscription_id ], :name => 'ix_subscription_profiles_subscription'
  end

  desc 'Drop Subscription management database tables'
  task :drop_tables => :connection do
    ActiveRecord::Base.connection.drop_table :subscription_profiles
    ActiveRecord::Base.connection.drop_table :subscriptions
  end

  # Use Rails connection when appropriate or fallback to local test db
  task :connection do
    connected = false
    begin
      begin
        connected = true if ActiveRecord::Base.connection
      rescue ActiveRecord::ConnectionNotEstablished
      end
    rescue NameError # ActiveRecord not loaded
    end
    require File.dirname(__FILE__) + "/../test/connection" unless connected
  end
end


