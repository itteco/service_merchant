require File.dirname(__FILE__) + '/../test_helper'
require "tracker"

class AuthorizeNetGatewayRemoteTest < Test::Unit::TestCase

  def setup
    credentials = fixtures(:authorize_net)
    assert @gw = RecurringBilling::AuthorizeNetGateway.new(credentials)
    @card = credit_card()
  end

  def test_crud_recurring_payment
    payment_options = {
          :subscription_name => 'Random subscription',
          :order => {:invoice_number => 'ODMX31337'}
          }
    recurring_options = {
          :start_date => Date.today,
          :occurrences => 10,
          :interval => '10d'
          }

    sum = rand(50000)+120
    billing_id = @gw.create(Money.us_dollar(sum), @card, payment_options, recurring_options)
    assert @gw.last_response.success?

    payment_options[:order] = {:invoice_number => 'ODMX17532'}

    another_sum = rand(50000)+120
    @gw.update(billing_id, Money.us_dollar(another_sum), @card, payment_options, {})
    assert @gw.last_response.success?

    assert_raise NotImplementedError do; @gw.inquiry(billing_id); end

    @gw.delete(billing_id)
    assert @gw.last_response.success?
    profile = RecurringPaymentProfile.find_by_gateway_reference(billing_id)
    assert_equal 'deleted', profile.status
    
    assert_raise StandardError do;@gw.update(billing_id, Money.us_dollar(another_sum), @card, payment_options, {});end;
  end

  def test_update_or_recreate
    payment_options = {
          :subscription_name => 'Random subscription',
          :order => {:invoice_number => 'ODMX31337'}
          }
    recurring_options = {
          :start_date => Date.today,
          :occurrences => 10,
          :interval => '10d'
          }

    sum = rand(50000)+120
    billing_id = @gw.create(Money.us_dollar(sum), @card, payment_options, recurring_options)
    assert @gw.last_response.success?

    payment_options[:order] = {:invoice_number => 'ODMX17532'}

    another_sum = rand(50000)+120
    @gw.update_or_recreate(billing_id, {:amount => Money.us_dollar(another_sum)})
    assert @gw.last_response.success?

    @gw.update_or_recreate(billing_id, {:card => @card, :start_date => Date.new(2009, 7, 8)})
    assert @gw.last_response.success?
  end

end
