require File.dirname(__FILE__) + '/../test_helper'

require 'money'

class SubscriptionManagementRemoteTest < Test::Unit::TestCase

  def setup
    @sm = ::SubscriptionManagement.new(
                  :tariff_plans_config => File.dirname(__FILE__) + '/../../samples/backpack.yml',
                  :taxes_config => File.dirname(__FILE__) + '/../../samples/taxes.yml',
                  :gateways_config => File.dirname(__FILE__) + '/../../../recurring_billing/test/fixtures.yml',
                  :gateway => :paypal
                  )
  end

  # Checks if there are no exceptions while manipulating class with legit data; based on demo.rb
  def test_crud_is_working
    options = {
              :account_id => 'test_acc_id',
              :account_country => 'US',
              :account_state => 'CA',
              :tariff_plan => 'solo_monthly',
              :start_date => (Date.today + 1),
              :quantity => 1,
              :end_date => DateTime.new(2010, 12, 11)
              }
    credit_card = credit_card()
    credit_card_2 = credit_card(4929838635250031, {:year => Time.now.year + 5})
    credit_card_3 = credit_card(4929273971564532, {:year => Time.now.year + 3})

    assert_raise StandardError do; @sm.get_active_profile(-1); end

    subscription_id = @sm.subscribe(options)
    assert_equal 'pending', Subscription.find_by_id(subscription_id).status
    assert_raise StandardError do; @sm.get_active_profile(subscription_id); end
    @sm.pay_for_subscription(subscription_id, credit_card, {})
    subscription = Subscription.find_by_id(subscription_id)
    assert_equal 'ok', subscription.status
    assert_equal 700, subscription.net_amount
    assert_equal 140, subscription.taxes_amount
    assert_equal 840, subscription.billing_amount

    assert_equal 1, subscription.recurring_payment_profiles.length
    profile = subscription.recurring_payment_profiles[0]
    assert_equal 700, profile.net_amount
    assert_equal 140, profile.taxes_amount
    assert_equal 840, profile.amount

    # create payment and check invoice
    time = DateTime.now
    transaction = Transaction.new({
        :recurring_payment_profile_id => profile.id,
        :gateway_reference => 'ABC0123456789XYZ',
        :currency => 'USD',
        :amount => 840,
        :created_at => time
        })
    transaction.save!

    invoice_data = @sm.get_invoice_data(transaction.id)
    invoice_data[:date] = invoice_data[:date].strftime('%Y-%m-%d')

    assert_equal({:taxes_comment    =>"resident, CA",
                 :net_amount        =>"7.00 USD",
                 :billing_account   =>"test_acc_id",
                 :transaction_gateway=>"PAYPAL",
                 :taxes_amount      =>"1.40 USD",
                 :transaction_id    =>"ABC0123456789XYZ",
                 :number            => transaction.id,
                 :date              => time.strftime('%Y-%m-%d'),
                 :transaction_amount=>"8.40 USD",
                 :total_amount      =>"8.40 USD",
                 :service_name      =>"Solo (per month)"
                 },
                invoice_data
                )

    transaction = Transaction.new({
        :recurring_payment_profile_id => profile.id,
        :gateway_reference => 'CAB0123456789ZYX',
        :currency => 'CAD',
        :amount => 840,
        :created_at => Date.today
        })
    transaction.save!
    assert_raises NotImplementedError do; @sm.get_invoice_data(transaction.id); end

    transaction = Transaction.new({
        :recurring_payment_profile_id => profile.id,
        :gateway_reference => 'CAB0123456789ZYX',
        :currency => 'USD',
        :amount => 839,
        :created_at => Date.today
        })
    transaction.save!
    assert_raises NotImplementedError do; @sm.get_invoice_data(transaction.id); end

    features = @sm.get_features(subscription_id)

    options = {:card=>credit_card_2}
    assert @sm.update_possible?(subscription_id, options)
    @sm.update_subscription(subscription_id, options)

    options = {:card=>credit_card_3, :start_date => Date.today + 42}
    assert !@sm.update_possible?(subscription_id, options)
    @sm.update_subscription(subscription_id, options)

    @sm.unsubscribe(subscription_id)
    assert_equal 'canceled', Subscription.find_by_id(subscription_id).status
  end

end
