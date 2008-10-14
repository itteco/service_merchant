#!/usr/bin/env ruby
require 'rubygems'
require 'test/unit'

require 'active_merchant'

require File.dirname(__FILE__) + '/../lib/gateways'

# Turn off invalid certificate crashes
require 'openssl'
silence_warnings do
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
end

ActiveMerchant::Billing::Base.mode = :test

module RecurringBilling
  module Assertions
    def assert_field(field, value)
      clean_backtrace do
        assert_equal value, @helper.fields[field]
      end
    end

    # Allows the testing of you to check for negative assertions:
    #
    #   # Instead of
    #   assert !something_that_is_false
    #
    #   # Do this
    #   assert_false something_that_should_be_false
    #
    # An optional +msg+ parameter is available to help you debug.
    def assert_false(boolean, message = nil)
      message = build_message message, '<?> is not false or nil.', boolean

      clean_backtrace do
        assert_block message do
          not boolean
        end
      end
    end

    # A handy little assertion to check for a successful response:
    #
    #   # Instead of
    #   assert_success response
    #
    #   # DRY that up with
    #   assert_success response
    #
    # A message will automatically show the inspection of the response
    # object if things go wrong.
    def assert_success(response)
      clean_backtrace do
        assert response.success?, "Response failed: #{response.inspect}"
      end
    end

    # The negative of +assert_success+
    def assert_failure(response)
      clean_backtrace do
        assert_false response.success?, "Response expected to fail: #{response.inspect}"
      end
    end

    def assert_valid(validateable)
      clean_backtrace do
        assert validateable.valid?, "Expected to be valid"
      end
    end

    def assert_not_valid(validateable)
      clean_backtrace do
        assert_false validateable.valid?, "Expected to not be valid"
      end
    end

    private
    def clean_backtrace(&block)
      yield
    rescue Test::Unit::AssertionFailedError => e
      path = File.expand_path(__FILE__)
      raise Test::Unit::AssertionFailedError, e.message, e.backtrace.reject { |line| File.expand_path(line) =~ /#{path}/ }
    end
  end
end

module Test
  module Unit
    class TestCase

      include RecurringBilling::Assertions
      include Utils

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
