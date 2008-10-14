class SubscriptionProfile < ActiveRecord::Base
belongs_to :subscription
belongs_to :recurring_payment_profile
end
