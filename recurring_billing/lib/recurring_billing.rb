require File.dirname(__FILE__) + '/dependencies'

# RecurringBilling module provides common API for managing recurring billing operations
# via remote gateway. All manipulations are done through instances of RecurringBillingGateway
# and its descendants (though direct use of that class descendants is discouraged).
#
# Please see RecurringBillingGateway for more detailed reference.
module RecurringBilling

  #:include:recurring_billing.rdoc
  #:include:recurring_billing_extension.rdoc
  class RecurringBillingGateway
    include ActiveMerchant::RequiresParameters
    attr_reader :last_response

    # Returns code that is used to identify the gateway
    def code
      raise NotImplementedError, 'Method is virtual'
    end

    # Returns gateway name
    def name
      raise NotImplementedError, 'Method is virtual'
    end

    # Creates a new recurring billing gateway
    def initialize(options)#:nodoc:
      @gateway =     ::ActiveMerchant::Billing::Base.gateway(code).new(
        :login      => options[:login],
        :password   => options[:password],
        :test       => options[:is_test].nil? ? false : options[:is_test], # false by default
        :signature  => options[:signature]
        )
      @last_response = nil
    end

    # Creates a recurring payment
    def create(amount, card, payment_options={}, recurring_options={})
      if correct_create?(amount, card, payment_options, recurring_options)
        create_specific(amount, card, payment_options, recurring_options)
      end
    end

    # Updates a recurring payment
    def update(billing_id, amount=nil, card=nil, payment_options={}, recurring_options={})
      if correct_update?(billing_id, amount, card, payment_options, recurring_options)
        update_specific(billing_id, amount, card, payment_options, recurring_options)
      end
    end

    # Deletes a recurring payment
    def delete(billing_id)
      delete_specific(billing_id)
    end

    # Asks for status of recurring payment
    def inquiry(billing_id)
      inquiry_specific(billing_id)
    end

    class << self
      # Converts single options hash into hash of parameters used by create|update methods
      #
      # :amount or :billing_amount => amount
      # :card => card
      # :subscription_name, :billing_address, :order, :taxes_amount_included => payment_options
      # :start_date, :interval, :end_date, :trial_end, :occurrences, :trial_occurrences => recurring_options
      def separate_create_update_params_from_options(options)
        payment_options, recurring_options = {}, {}
        amount = options[:billing_amount] unless amount = options[:amount]
        card = options[:card]
        options.each do |k,v|
          payment_options[k] = v if [:subscription_name, :billing_address, :order, :taxes_amount_included].include?(k)
          recurring_options[k] = v if [:start_date, :interval, :end_date, :trial_end, :occurrences, :trial_occurrences, :trial_days, :pay_on_day_x].include?(k)
        end

        return {:amount => amount, :card => card, :payment_options => payment_options, :recurring_options => recurring_options}
      end


      # Returns an instance of RecurringBillingGateway for selected gateway
      #
      # options <= hash of :gateway, :login, :password, :is_test(optional), :signature(optional)
      def get_instance(options)
        raise ArgumentError, ':gateway key is required' unless options.has_key?(:gateway)

        gateway = RecurringBilling.const_get("#{options[:gateway].to_s.downcase}_gateway".camelize)
        gateway.new(options)
      end
    end

    ###
    protected
    # Checks whether requested change can be done via simple update (or recreate needed)
    def correct_update?(billing_id, amount, card, payment_options, recurring_options)
      raise NotImplementedError, 'Method is virtual'
    end

    # Make an update using gateway-specific actions
    def update_specific(billing_id, amount, card, payment_options, recurring_options)
      raise NotImplementedError, 'Method is virtual'
    end
    # Checks whether passed parameters of requested recurring payment conform to specification
    def correct_create?(amount, card, payment_options, recurring_options)
        raise ArgumentError, 'Card must be of ActiveMerchant::Billing::CreditCard' unless card.is_a?(ActiveMerchant::Billing::CreditCard)
      if (!recurring_options) || !(recurring_options.has_key?(:end_date) || recurring_options.has_key?(:occurrences))
        raise StandardError, 'Either payments'' end date or number of payment occurences should be set'
      end
      return true
    end

    # Creates a recurring payment using gateway-specific actions (virtual)
    def create_specific(amount, card, payment_options, recurring_options)
      raise NotImplementedError, 'Method is virtual'
    end

    # Deletes a recurring payment
    def delete_specific(billing_id)
      raise NotImplementedError, 'Method is virtual'
    end

    # Inquires status of given subscription profile on payment gateway.
    def inquiry_specific(billing_id)
      raise NotImplementedError, 'Method is virtual'
    end

  end
end

require File.dirname(__FILE__) + "/gateways"
