class Subscription < ActiveRecord::Base
  has_many :subscription_profiles
  has_many :recurring_payment_profiles, :through => :subscription_profiles

  # Returns billing amount (sum of net amount + taxes) 
  def billing_amount
    self.net_amount + self.taxes_amount
  end
end
