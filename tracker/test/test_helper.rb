#!/usr/bin/env ruby

require 'rubygems'
require 'test/unit'
require 'activesupport'

silence_warnings do
  require 'active_merchant'
end

require File.dirname(__FILE__) + "/connection"

$: << File.dirname(__FILE__) + "/../" # Tracker root

require 'tracker'

# Turn off invalid certificate crashes
require 'openssl'
silence_warnings do
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
end

ActiveMerchant::Billing::Base.mode = :test

module Test
  module Unit
    class TestCase


      DEFAULT_CREDENTIALS = File.dirname(__FILE__) + '/fixtures.yml'

      private
      def credit_card(number = '4242424242424242', options = {})
        defaults = {
          :number => number,
          :month => 9,
          :year => Time.now.year + 1,
          :first_name => 'John',
          :last_name => 'Doe',
          :verification_value => '123',
          :type => 'visa'
        }.update(options)

        ActiveMerchant::Billing::CreditCard.new(defaults)
      end

      def address(options = {})
        {
          :name => 'John Doe',
          :address1 => '1234 My Street',
          :address2 => 'Apt 1',
          :company => 'Widgets Inc',
          :city => 'Ottawa',
          :state => 'ON',
          :zip => 'K1C2N6',
          :country => 'CA',
          :phone => '(555)555-5555'
        }.update(options)
      end

      def all_fixtures
        @@fixtures ||= load_fixtures
      end

      def fixtures(key)
        data = all_fixtures[key] || raise(StandardError, "No fixture data was found for '#{key}'")

        data.dup
      end

      def load_fixtures
        file = DEFAULT_CREDENTIALS
        yaml_data = YAML.load(File.read(file))
        symbolize_keys(yaml_data)

        yaml_data
      end

      def symbolize_keys(hash)
        return unless hash.is_a?(Hash)

        hash.symbolize_keys!
        hash.each{|k,v| symbolize_keys(v)}
      end
    end
  end
end
