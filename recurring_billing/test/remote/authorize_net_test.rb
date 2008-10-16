require File.dirname(__FILE__) + '/../test_helper'

class AuthorizeNetGatewayRemoteTest < Test::Unit::TestCase
  
  def setup
    credentials = fixtures(:authorize_net)
    assert @gw = RecurringBilling::AuthorizeNetGateway.new(credentials.update({:is_test => true}))
    assert_equal @gw.name, 'Authorize.net'
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

    billing_id = @gw.create(Money.us_dollar(15), @card, payment_options, recurring_options)
    print "Create:\n"
    print @gw.last_response.inspect
    payment_options[:order] = {:invoice_number => '407934'}
    @gw.update(billing_id, Money.us_dollar(16), @card, payment_options, nil)
    print "\nUpdate:\n"
    print @gw.last_response.inspect
    @gw.delete(billing_id)
    print "\nDelete:\n"
    print @gw.last_response.inspect
    assert true
  end
  
end
