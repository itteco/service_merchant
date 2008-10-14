class Transaction < ActiveRecord::Base
  # We cannot just use `table_name_prefix = "tracker_"' because it uses broken
  # cattr_accessor and applies to all ActiveRecord::Base descendants when
  # tracker is loaded from Subscription Manager
  def self.table_name_prefix
    "tracker_"
  end

  belongs_to :recurring_payment_profile

  def money
    Money.new(self.amount, self.currency)
  end

  def money_formatted
    '%.2f %s' % [self.amount/100.00, self.currency.upcase]
  end

end
