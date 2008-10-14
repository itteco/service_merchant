#!/usr/bin/ruby
#
# Demo of subscription management
require File.dirname(__FILE__) + '/subscription_management/subscription_management'

require 'rubygems'
require 'active_merchant'

options = {
          :account_id => 'Test',
          :account_country => 'US',
          :account_state => 'CA',
          :tariff_plan => 'solo_monthly',
          :start_date => (Date.today + 1),
          :quantity => 1,
          :end_date => DateTime.new(2010, 12, 11)
          }
credit_card = ActiveMerchant::Billing::CreditCard.new({
          :number => 4242424242424242,
          :month => 9,
          :year => Time.now.year + 1,
          :first_name => 'John',
          :last_name => 'Doe',
          :verification_value => '123',
          :type => 'visa'
        })

credit_card_2 = ActiveMerchant::Billing::CreditCard.new({
          :number => 4929838635250031,
          :month => 9,
          :year => Time.now.year + 5,
          :first_name => 'John',
          :last_name => 'Doe',
          :verification_value => '123',
          :type => 'visa'
        })
        
credit_card_3 = ActiveMerchant::Billing::CreditCard.new({
          :number => 4929273971564532,
          :month => 12,
          :year => Time.now.year + 3,
          :first_name => 'John',
          :last_name => 'Doe',
          :verification_value => '123',
          :type => 'visa'
        })

sm = SubscriptionManagement.new(
          :tariff_plans_config => 'subscription_management/samples/backpack.yml',
          :taxes_config => 'subscription_management/samples/taxes.yml',
          :gateways_config => 'recurring_billing/test/fixtures.yml',
          :gateway => :paypal
          )

subscription_id = sm.subscribe(options)
sm.pay_for_subscription(subscription_id, credit_card, {})
features = sm.get_features(subscription_id)
for feature in features
  print "\n"+SubscriptionManagement.format_feature(feature)
end

options_sets = [{:card=>credit_card_2}, {:card=>credit_card_3, :start_date => Date.today + 42}]
options_sets.each do |options|
  print "\nTrying to update subscription using options: #{options.inspect}"
  print "\nWarning: current billing profile on gateway will be canceled and re-created" unless sm.update_possible?(subscription_id, options)
  sm.update_subscription(subscription_id, options)
end

sm.unsubscribe(subscription_id)
