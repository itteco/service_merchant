class Subscription < ActiveRecord::Base
  has_many :subscription_profiles
  has_many :recurring_payment_profiles, :through => :subscription_profiles

  # Returns billing amount (sum of net amount + taxes) 
  def billing_amount
    self.net_amount + self.taxes_amount
  end

  # Recalculate price and taxes
  # 
  # subscription_config should be initialized SubscriptionManagement instance
  def recalc_price(subscription_config)
    total_tax = subscription_config.all_taxes[self.taxes_id]["taxes"].inject(0){|sum,item| sum + item["rate"]} # sum all applicable taxes
    self.net_amount = self.quantity * subscription_config.all_tariff_plans[self.tariff_plan_id]["price"]
    self.taxes_amount = self.net_amount * total_tax
  end

  def update_quantity(qty, subscription_config)
    self.quantity = qty
    self.recalc_price(subscription_config)
    self.save
  end
end
