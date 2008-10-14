class RecurringPaymentProfile < ActiveRecord::Base
  # We cannot just use `table_name_prefix = "tracker_"' because it uses broken
  # cattr_accessor and applies to all ActiveRecord::Base descendants when
  # tracker is loaded from Subscription Manager
  def self.table_name_prefix
    "tracker_"
  end
  has_many :transactions

  # Returns single payment amount (sum of net amount and taxes)
  def amount
    self.net_amount+self.taxes_amount
  end

  def money
    Money.new(self.amount, self.currency)
  end

  # Sets net amount
  def net_money=(x_amount)
    self[:net_amount] = x_amount.cents
    if !self[:currency].nil? && x_amount.currency != self[:currency]
      raise ArgumentError, 'Cannot change currency. Please, clean it first'
    end
    self[:currency] = x_amount.currency
  end

  # Sets taxes amount
  def taxes_money=(x_amount)
    self[:taxes_amount] = x_amount.cents
    if !self[:currency].nil? && x_amount.currency != self[:currency]
      raise ArgumentError, 'Cannot change currency. Please, clean it first'
    end
    self[:currency] = x_amount.currency
  end

  # Parses card and set related fields. 
  def parse_and_set_card(card, hint=nil)
    self[:card_type] = card.type
    number = card.number
    default_hint = "#{card.first_name} #{card.last_name}, #{card.type.upcase}, #{mask_card_number(number)}, exp. #{card_exp_date(card)}"
    self[:card_owner_memo] = (hint) ? hint : default_hint
  end

  # Masks card number (only last 4 digits are shown)
  #
  # Example:
  # '031641616161' => 'XXXXXXXX6161'
  def mask_card_number(number)
    number.to_s.size < 5 ? number.to_s : (('X' * number.to_s[0..-5].length) + number.to_s[-4..-1])
  end

  # Returns formatted expiration date for given Card object
  def card_exp_date(card)
    '%04d-%02d' % [card.year, card.month]
  end

  # Returns formatted amount for current record
  def money_formatted
    '%.2f %s' % [self.amount/100.00, self.currency.upcase]
  end

  def net_money_formatted
    '%.2f %s' % [self.net_amount/100.00, self.currency.upcase]
  end

  def taxes_money_formatted
    '%.2f %s' % [self.taxes_amount/100.00, self.currency.upcase]
  end

  # Marks current profile as active and saves it
  def set_profile_active_and_save!
    self.status = 'active'
    self.save
  end

  # Updates profile fields after it was UPDATEd via remote gateway
  def set_profile_after_update!(amount, card, payment_options, recurring_options)

    if amount
      # Split amount into net/taxes
      if payment_options.has_key?(:taxes_amount_included)
        self.net_money = amount - payment_options[:taxes_amount_included]
        self.taxes_money = payment_options[:taxes_amount_included]
        payment_options.delete(:taxes_amount_included)
      else
        self.net_money = amount
        self.taxes_amount = 0
      end
    end

    self.parse_and_set_card(card) if card
    self.subscription_name = payment_options[:subscription_name] if payment_options[:subscription_name]
    unless (ro = recurring_options).empty?
      self.pay_on_day_x = ro[:pay_on_day_x] unless ro[:pay_on_day_x].nil?
    end
    self.save
  end

  # Updates profile fields after it was INQUIREDd via remote gateway
  def set_profile_after_inquiry!(result)
    self.status = result['profile_status']
    self.outstanding_balance = result['outstanding_balance'].cents
    self.complete_payments_count = result['number_cycles_completed']
    self.failed_payments_count = result['failed_payment_count']
    self.remaining_payments_count = result['number_cycles_remaining']
    self.last_synchronized_at = DateTime.now
    self.save
  end

  # Updates given hash from current profile fields
  def update_options_from_profile!(options)
    options[:subscription_name] ||= self[:subscription_name]
    options[:amount] ||= Money.new(self.amount, self[:currency])
    options[:taxes_amount_included] ||= Money.new(self.taxes_amount, self[:currency])
    options[:interval] ||= self[:periodicity]
    options[:start_date] ||= (Date.new(self[:created_at].year,self[:created_at].month, self[:created_at].mday) + self[:trial_days].to_i)
    unless options[:trial_days]
      trial_days = options[:start_date] - Date.today
      options[:trial_days] = trial_days if trial_days > 0
    end
    self[:complete_payments_count] = 0 unless self[:complete_payments_count].to_i > 0
    options[:occurrences] = self[:total_payments_count] - self[:complete_payments_count]
    options[:pay_on_day_x] ||= self[:pay_on_day_x]
  end

  # Marks profile as deleted
  def mark_as_deleted!
    self[:deleted_at] = Time.now
    self[:status] = 'deleted'
    self.save
  end

end
