require File.dirname(__FILE__) + '/../test_helper'

class RecurringBillingGatewayTest < Test::Unit::TestCase

  def perform_generic_test(gateway)
    credentials = fixtures(gateway)
    assert gw = RecurringBilling::RecurringBillingGateway.get_instance(credentials)
  end

  # Checking separate_create_update_params_from_options method  
  def test_separate_create_update_params_from_options
    cc = credit_card()
    payment_options = {
          :subscription_name => 'Test Subscription 1337',
          :order => {:invoice_number => '000000'}
          }
    recurring_options = {
          :start_date => Date.today + 1,
          :end_date => Date.today + 290,
          :interval => '1m'
          }
    all_options = {}.update({:card => cc}).update(payment_options).update(recurring_options)
    separate_options = RecurringBilling::RecurringBillingGateway.separate_create_update_params_from_options(all_options)
    assert_equal separate_options, {:amount => nil, :card => cc, :payment_options => payment_options, :recurring_options => recurring_options}
  end

  def test_paypal
    perform_generic_test(:paypal)
  end

  def test_authorize_net
    perform_generic_test(:authorize_net)
  end
  
end
