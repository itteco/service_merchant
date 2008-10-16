require File.dirname(__FILE__) + '/../test_helper'

class PaypalGatewayRemoteTest < Test::Unit::TestCase

  def setup
    cred = fixtures(:paypal)
    assert @gw = RecurringBilling::PaypalGateway.new(cred.update({:is_test=>true}))
    assert_equal @gw.name, 'PayPal Website Payments Pro (US)'
    @card = credit_card()
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

    print "\nCreate:\n"
    billing_id = @gw.create(Money.us_dollar(15), @card, payment_options=payment_options, recurring_options=recurring_options)
    print @gw.last_response.inspect
    payment_options[:order] = {:invoice_number => '407934'}
    assert @gw.last_response.success?

    print "\n\nUpdate:\n"
    @gw.update(billing_id, Money.us_dollar(16), @card, payment_options=payment_options)
    print @gw.last_response.inspect
    assert @gw.last_response.success?

    print "\n\nInquiry:\n"
    result = @gw.inquiry(billing_id)
    print @gw.last_response.inspect
    print "\n\n", result.inspect
    assert @gw.last_response.success?

    print "\n\nDelete:\n"
    @gw.delete(billing_id)
    print @gw.last_response.inspect
    assert @gw.last_response.success?
  end

end
