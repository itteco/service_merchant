namespace :tracker do
  desc 'Create Tracker database tables'
  task :create_tables => :connection do
    ActiveRecord::Base.connection.create_table :tracker_recurring_payment_profiles, :force => true do |t|
      t.column :gateway_reference,          :string, :unique => true
      t.column :gateway,                    :string
      t.column :subscription_name,          :text
      t.column :description,                :text
      t.column :currency,                   :string
      t.column :net_amount,                 :integer, :null => false
      t.column :taxes_amount,               :integer, :null => false
      t.column :outstanding_balance,        :integer
      t.column :total_payments_count,       :integer
      t.column :complete_payments_count,    :integer
      t.column :failed_payments_count,      :integer
      t.column :remaining_payments_count,   :integer
      t.column :periodicity,                :string
      t.column :trial_days,                 :integer, :default => 0
      t.column :pay_on_day_x,               :integer, :default => 0
      t.column :status,                     :string
      t.column :problem_status,             :string
      t.column :card_type,                  :string
      t.column :card_owner_memo,            :string
      t.column :created_at,                 :datetime
      t.column :updated_at,                 :datetime
      t.column :deleted_at,                 :datetime
      t.column :last_synchronized_at,       :datetime
    end
    ActiveRecord::Base.connection.add_index :tracker_recurring_payment_profiles, [ :gateway ], :name => 'ix_tracker_recurring_payment_profiles_gateway'
    ActiveRecord::Base.connection.add_index :tracker_recurring_payment_profiles, [ :gateway_reference ], :unique => true, :name => 'uix_tracker_recurring_payment_profiles_gateway_reference'
    ActiveRecord::Base.connection.create_table :tracker_transactions, :force => true do |t|
      t.column :recurring_payment_profile_id, :integer
      t.column :gateway_reference,            :string
      t.column :currency,                     :string
      t.column :amount,                       :integer
      t.column :result_code,                  :string
      t.column :result_text,                  :string
      t.column :card_type,                    :string
      t.column :card_owner_memo,              :string
      t.column :created_at,                   :datetime
      t.column :recorded_at,                  :datetime
    end
    ActiveRecord::Base.connection.add_index :tracker_transactions, [ :recurring_payment_profile_id ]
  end

  desc 'Drop Tracker database tables'
  task :drop_tables => :connection do
    ActiveRecord::Base.connection.drop_table :tracker_recurring_payment_profiles
    ActiveRecord::Base.connection.drop_table :tracker_transactions
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


