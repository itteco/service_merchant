require File.dirname(__FILE__) + '/../test_helper'

class AuthorizeNetGatewayTest < Test::Unit::TestCase
  
  def setup
    credentials = fixtures(:authorize_net)
    assert @gw = RecurringBilling::AuthorizeNetGateway.new(credentials.update({:is_test => true}))
    assert_equal @gw.name, 'Authorize.net'
    @card = credit_card()
  end

  def test_correct_update?
    #def correct_update?(billing_id, amount, card, payment_options, recurring_options)
    subscr_id = 'SOMERANDOMID'
    assert_raise StandardError do; @gw.correct_update?(subscr_id, nil, @card, nil, {:start_date => Date.today + 1}); end
    assert_nothing_thrown do;@gw.correct_update?(subscr_id, 1, @card, nil, nil);end
    assert_nothing_thrown do;@gw.correct_update?(subscr_id, 100, @card, nil, {});end
    
  end
  
  def test_transform_dates
    def d(string);return Date.parse(string);end
    def h(a,b,c,d);return {:interval=>{:length=>a, :unit=>b}, :duration=>{:start_date=>c, :occurrences=>d}};end
    
    #syntax is: transform_dates(start_date, interval, occurrences, end_date)
    assert_raise ArgumentError do; @gw.transform_dates(d('2008/01/01'), '5m', nil, nil); end
    assert_raise ArgumentError do; @gw.transform_dates(d('2008/01/01'), '5m', 5, d('2009/01/01')); end
    assert_raise ArgumentError do; @gw.transform_dates(d('2008/01/01'), 'm', 1, nil); end
    assert_raise ArgumentError do; @gw.transform_dates(d('2008/01/01'), '0.5m', 1, nil); end
    assert_raise ArgumentError do; @gw.transform_dates(d('2008/01/01'), '1 year', 1, nil); end
    assert_raise ArgumentError do; @gw.transform_dates(d('2008/01/01'), '8', 1, nil); end
    assert_raise ArgumentError do; @gw.transform_dates(d('2008/01/01'), '5m', -1, nil); end
    assert_raise ArgumentError do; @gw.transform_dates(d('2008/01/01'), '5m', nil, d('2007/12/31')); end
    
    assert_equal @gw.transform_dates(d('2008/01/01'), '5m', 7, nil), h(5,:months,d('2008/01/01'),7)
    assert_equal @gw.transform_dates(d('2008/01/01'), '3 d', nil, d('2008/01/19')), h(3,:days,d('2008/01/01'),7)
    assert_equal @gw.transform_dates(d('2008/01/01'), '3d', nil, d('2008/01/21')), h(3,:days,d('2008/01/01'),7)
    assert_equal @gw.transform_dates(d('2008/01/01'), '8w', 13, nil), h(56,:days,d('2008/01/01'),13)
    assert_equal @gw.transform_dates(d('2008/01/01'), '1y', nil, d('2010/12/01')), h(12,:months,d('2008/01/01'),3)
  end

end
