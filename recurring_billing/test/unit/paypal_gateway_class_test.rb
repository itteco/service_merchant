require File.dirname(__FILE__) + '/../test_helper'

class PaypalGatewayTest < Test::Unit::TestCase

  def setup
    cred = fixtures(:paypal)
    assert @gw = RecurringBilling::PaypalGateway.new(cred.update({:is_test=>true}))
    assert_equal @gw.name, 'PayPal Website Payments Pro (US)'
    @card = credit_card()
  end

  def test_true
  end

#  def test_correct_update?
#    #def correct_update?(billing_id, amount, card, payment_options, recurring_options)
#    subscr_id = 'SOMERANDOMID'
#    assert_raise StandardError do; @gw.correct_update?(subscr_id, nil, @card, nil, {:start_date => Date.today + 1}); end
#    assert_nothing_thrown do;@gw.correct_update?(subscr_id, 1, @card, nil, nil);end
#    assert_nothing_thrown do;@gw.correct_update?(subscr_id, 100, @card, nil, {});end
#  end

end
