require File.dirname(__FILE__) + '/../test_helper'

class RecurringBillingRemoteTest < Test::Unit::TestCase

  def setup
    @card = credit_card()
  end

  def perform_generic_test(gateway)
    random_invoice = "%06d" % rand(999999)
    payment_options = {
          :subscription_name => 'Test Subscription 1337',
          :order => {:invoice_number => random_invoice}
          }
    recurring_options = {
          :start_date => Date.today + 1,
          :end_date => Date.today + 290,
          :interval => '1m'
          }
    credentials = fixtures(gateway)
    assert gw = RecurringBilling::RecurringBillingGateway.get_instance(credentials)

    billing_id = gw.create(Money.us_dollar(15), @card, payment_options, recurring_options)
    assert gw.last_response.success?
    new_random_invoice = "%06d" % rand(999999)
    payment_options[:order] = {:invoice_number => new_random_invoice}
    gw.update(billing_id, Money.us_dollar(16), @card, payment_options, {})
    assert gw.last_response.success?
    gw.delete(billing_id)
    assert gw.last_response.success?
  end

  def test_paypal
    perform_generic_test(:paypal)
  end

  def test_authorize_net
    perform_generic_test(:authorize_net)
  end

end
