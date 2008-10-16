require File.dirname(__FILE__) + '/../test_helper'

require "mocha"
require "tracker"

class PaypalRemoteTest < Test::Unit::TestCase

  def setup
    cred = fixtures(:paypal)
    assert @gw = RecurringBilling::PaypalGateway.new(cred)
    @card = credit_card()
    @card2 = credit_card('4929838635250031', {:first_name => 'James', :last_name => 'Lueser'})
    @card_bogus = credit_card("ISMELLLIKEBOGUS")
  end

  def test_inquiry_updates_tracker
    payment_options = {
          :subscription_name => 'Test Subscription 1337',
          :order => {:invoice_number => '407933'}
          }
    recurring_options = {
          :start_date => Date.today + 1,
          :end_date => Date.today + 290,
          :interval => '1m'
          }

    billing_id = @gw.create(Money.us_dollar(15), @card, payment_options=payment_options, recurring_options=recurring_options)
    assert @gw.last_response.success?

    profile = RecurringPaymentProfile.find_by_gateway_reference(billing_id)
    assert_equal 'active', profile.status
    assert_not_equal -1, profile.outstanding_balance
    assert_not_equal -1, profile.complete_payments_count
    assert_not_equal -1, profile.failed_payments_count
    assert_not_equal -1, profile.remaining_payments_count

    # Mock result of original inquire methods
    result_mock = {'profile_status'         => 'verified',
                'outstanding_balance'    => ::Money.new(-100),
                'number_cycles_completed'=> -1,
                'failed_payment_count'   => -1,
                'number_cycles_remaining'=> -1}

    @gw.methods.include? :inquiry_without_persist
    @gw.expects(:inquiry_without_persist).returns(result_mock)
    result = @gw.inquiry(billing_id)
    assert @gw.last_response.success?

    assert_equal result_mock, result

    # Get profile and check whether data is updated
    profile = RecurringPaymentProfile.find_by_gateway_reference(billing_id)
    assert_equal 'verified', profile.status
    assert_equal -100, profile.outstanding_balance
    assert_equal -1, profile.complete_payments_count
    assert_equal -1, profile.failed_payments_count
    assert_equal -1, profile.remaining_payments_count
  end

  def test_create_update_failure
      payment_options = {
            :subscription_name => 'Unsuccessful payment',
            :order => {:invoice_number => '032895'}
            }
      recurring_options = {
            :start_date => Date.today + 1,
            :occurrences => 402,
            :interval => '1w'
            }

      new_recurring_options = {
            :pay_on_day_x => 3
            }

      token_sum = rand(50000)+120
      @gw.create(Money.us_dollar(token_sum), @card_bogus, payment_options=payment_options, recurring_options=recurring_options)
      assert !@gw.last_response.success?
      assert RecurringPaymentProfile.find_by_net_amount(Money.us_dollar(token_sum).cents).nil?

      new_token_sum = rand(50000)+120
      billing_id = @gw.create(Money.us_dollar(new_token_sum), @card, payment_options=payment_options, recurring_options=recurring_options)
      assert @gw.last_response.success?
      assert_equal profile = RecurringPaymentProfile.find_by_net_amount(Money.us_dollar(new_token_sum).cents), RecurringPaymentProfile.find_by_gateway_reference(billing_id)

      another_token_sum = rand(50000)+120
      @gw.update(billing_id, Money.us_dollar(another_token_sum), @card, {}, new_recurring_options)
      assert_not_equal profile.updated_at, (profile2 = RecurringPaymentProfile.find_by_gateway_reference(billing_id)).updated_at #meaning the profile hadn't been updated
      assert_equal profile2.amount, Money.us_dollar(another_token_sum).cents


      @gw.update(billing_id, Money.us_dollar(new_token_sum), @card_bogus, {}, {})
      assert_equal profile2.updated_at, RecurringPaymentProfile.find_by_gateway_reference(billing_id).updated_at #meaning the profile hadn't been updated
  end

  def test_update_or_create
    payment_options = {
          :subscription_name => 'Random subscription',
          :order => {:invoice_number => 'ODMX31337'}
          }
    recurring_options = {
          :start_date => Date.today,
          :occurrences => 10,
          :interval => '10 w'
          }

    sum = rand(50000)+120
    billing_id = @gw.create(Money.us_dollar(sum), @card, payment_options, recurring_options)
    assert @gw.last_response.success?

    another_sum = rand(50000)+120
    @gw.update_or_recreate(billing_id, {:card => @card2, :occurrences => 20})
    assert @gw.last_response.success?
  end

end
