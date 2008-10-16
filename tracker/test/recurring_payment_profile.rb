require File.dirname(__FILE__) + '/test_helper'

class RandomRecurringProfileTest < Test::Unit::TestCase

  def setup
    cred = fixtures(:paypal)
    assert @gw = RecurringBilling::PaypalGateway.new(cred)
    @card = credit_card(number='4532130086825928')
  end

  def test_crud_recurring_payment
    payment_options = {
          :subscription_name => 'Test Subscription 1337',
          :order => {:invoice_number => '407933'}
          }
    recurring_options = {
          :start_date => Date.today + 1,
          :end_date => Date.today + 290,
          :interval => '1m'
          }

    billing_id = @gw.create_with_persist(Money.us_dollar(15), @card, payment_options=payment_options, recurring_options=recurring_options)
    print "\n\nCreate:\n"
    print @gw.last_response.inspect
    payment_options[:order] = {:invoice_number => '407934'}
    @gw.update_with_persist(billing_id, Money.us_dollar(16), @card, payment_options=payment_options)
    print "\n\nUpdate:\n"
    print @gw.last_response.inspect
    @gw.delete_with_persist(billing_id)
    print "\n\nDelete:\n"
    print @gw.last_response.inspect
  end

end

