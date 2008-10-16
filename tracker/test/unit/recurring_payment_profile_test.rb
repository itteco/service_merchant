require File.dirname(__FILE__) + '/../test_helper'

require 'money'

class RecurringPaymentProfileTest < Test::Unit::TestCase

  def setup
    @profile = ::RecurringPaymentProfile.new
  end

  def test_net_money_assigns
    @profile.net_money=Money.new(333, currency='CAD')
    assert_equal 333, @profile.net_amount
    assert_equal 'CAD', @profile.currency
  end

  def test_taxes_money_assigns
    @profile.taxes_money=Money.new(444, currency='RUR')
    assert_equal 444, @profile.taxes_amount
    assert_equal 'RUR', @profile.currency
  end

  def test_net_money_fails
    @profile.taxes_money=Money.new(333, currency='CAD')
    assert_raise ArgumentError do; @profile.net_money=Money.new(444, currency='RUR'); end
  end

  def test_taxes_money_fails
    @profile.net_money=Money.new(333, currency='CAD')
    assert_raise ArgumentError do; @profile.taxes_money=Money.new(444, currency='RUR'); end
  end

  def test_mask_card_number
    assert_equal 'abba', @profile.mask_card_number('abba')
    assert_equal 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXched', @profile.mask_card_number('whatisthethingthatcannotbetouched')
  end

  def test_parse_and_set_card
    card = credit_card(number='1111111111', options={:type => 'master', :year => 2003, :month => 3, :first_name => 'Name', :last_name => 'Surname'})
    @profile.parse_and_set_card(card)
    assert_equal 'master', @profile.card_type
    assert_equal 'Name Surname, MASTER, XXXXXX1111, exp. 2003-03', @profile.card_owner_memo
  end

  def test_parse_and_set_card_with_hint
    card = credit_card(number='1111111111', options={:type => 'master'})
    @profile.parse_and_set_card(card, 'this is my hint')
    assert_equal 'master', @profile.card_type
    assert_equal 'this is my hint', @profile.card_owner_memo
  end

  def test_card_exp_date
    card = credit_card(number='4242424242424242', options={:year => 2001, :month => 1})
    assert_equal '2001-01', @profile.card_exp_date(card)
  end

  def test_no_obsolete_fields
    assert_raise NoMethodError do; @profile.payment_offset = 0; end
    assert_raise NoMethodError do; @profile.payments_start_on = Date.today; end
  end

end
