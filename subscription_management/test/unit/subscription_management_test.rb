require File.dirname(__FILE__) + '/../test_helper'

require 'money'

class SubscriptionManagementTest < Test::Unit::TestCase

  def setup
    @smc = SubscriptionManagement
  end

  def test_format_feature
    feature = {'quantity' => 5, 'feature' => {'name'=> 'Quota', 'unit'=> 'Gigabyte'}}
    assert_equal 'Quota: 5 Gigabytes', @smc.format_feature(feature)
    feature = {'quantity' => 1, 'feature' => {'name'=> 'Quota', 'unit'=> 'Gigabyte'}}
    assert_equal 'Quota: 1 Gigabyte', @smc.format_feature(feature)
    feature = {'quantity' => 0, 'feature' => {'name'=> 'Quota', 'unit'=> 'Gigabyte'}}
    assert_equal 'Quota: Unlimited', @smc.format_feature(feature)
    feature = {'quantity' => 2, 'feature' => {'name'=> 'Users'}}
    assert_equal 'Users: 2', @smc.format_feature(feature)
    feature = {'feature' => {'name'=> 'SSL Encryption'}}
    assert_equal 'SSL Encryption', @smc.format_feature(feature)
  end

  def test_format_periodicity
    assert_equal 'twice a week', @smc.format_periodicity('0.5 w') 
    assert_equal 'each month', @smc.format_periodicity('1 m')
    assert_equal 'each 2 years', @smc.format_periodicity('2 y')
    assert_equal 'each 42 days', @smc.format_periodicity('42 d')
    assert_raise ArgumentError do; x = @smc.format_periodicity('random'); end;
  end
  
  def test_get_taxes_id
    taxes = {"ca"=>{"country"=>"CA", "taxes"=>[{"tax"=>{"name"=>"Goods and Services Tax"}, "rate"=>0.05}], "state"=>"*"},
             "us_ca"=>{"country"=>"US", "taxes"=>[{"tax"=>{"name"=>"Sample tax"}, "rate"=>0.2}], "state"=>"CA"}}
    assert_equal 'ca', @smc.get_taxes_id(taxes, 'CA', 'ON')
    assert_equal 'us_ca', @smc.get_taxes_id(taxes, 'US', 'CA')
    assert_raise StandardError do; x = @smc.get_taxes_id(taxes, 'US', 'NY'); end
  end

end
