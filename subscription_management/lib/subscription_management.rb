require 'yaml'
require File.dirname(__FILE__) + '/../../recurring_billing/lib/recurring_billing'
require File.dirname(__FILE__) + '/../../tracker/tracker'
require 'rubygems'
require 'active_support/inflector'

#module SubscriptionManagement

  # This class allows handling of user subscriptions for given merchant service. See {PROJECT_ROOT}/demo.rb for usage example.
  class SubscriptionManagement
    attr_accessor :all_tariff_plans, :all_taxes, :tariff_plans_namespace, :all_gateways, :gateway

    # Constructs new SubscriptionManagement object
    #
    # Optional +options+ hash may include:
    #
    # definition of tariff plan config by config file name
    # - :tariff_plans_config - string defining name of YML file to read tariff plan configuration from
    # definition of tariff plan config by specifying tariff plans and its namespace directly (only if :tariff_plans_config is not present)
    # - :all_tariff_plans - hash containing tariff plans
    # - :tariff_plans_namespace - string defining namespace for given tariff plans
    # definition of tax config by config file name
    # - :taxes_config - string defining name of YML file to read taxes configuration from
    # definition of tax config by specifying tariff plans and its namespace directly (only if :taxes_config is not present)
    # - :all_taxes - hash containing taxes
    # definition of gateways config by config file name
    # - :gateways_config - string defining name of YML file to read gateways configuration from
    # definition of tax config by specifying tariff plans and its namespace directly (only if :gateways_config is not present)
    # - :all_gateways - hash containing gateways
    # definition of default gateway
    # - :gateway - Symbol or string containing gateway name  
    def initialize(options={})
      if options[:tariff_plans_config]
        @all_tariff_plans = SubscriptionManagement.get_all_tariff_plans(options[:tariff_plans_config])
        @tariff_plans_namespace = File.basename(options[:tariff_plans_config], '.yml').downcase.camelize
      else
        if options[:all_tariff_plans]
          @all_tariff_plans = options[:all_tariff_plans]
        end
        if options[:tariff_plans_namespace]
          @tariff_plan_namespace = options[:tariff_plans_namespace]
        end
      end

      if options[:taxes_config]
        @all_taxes = SubscriptionManagement.get_all_taxes(options[:taxes_config])
      elsif options[:taxes]
        @all_taxes = options[:all_taxes]
      end

      if options[:gateways_config]
        @all_gateways = SubscriptionManagement.get_gateway_settings(options[:gateways_config])
      elsif options[:all_gateways]
        @all_gateways = options[:all_gateways]
      end

      if [String, Symbol].include? options[:gateway].class
        @gateway = @all_gateways[options[:gateway].to_sym]
      elsif options[:gateway].class == Hash
        @gateway = options[:gateway]
      end

      return self
    end

    # Returns the most applicable identifier of tax area settings available for given country and state (instance)
    def get_applicable_taxes_id(country, state)
      return SubscriptionManagement.get_taxes_id(@all_taxes, country, state)
    end

    # Subscribe account for tariff plan, specified in "all_tariff_plans" property of an instance
    #
    # options hash should/may include following keys:
    #   :account_id
    #   :account_country
    #   :account_state
    #   :tariff_plan
    #   :start_date
    #   :quantity
    #   :end_date
    def subscribe(options)
      subscription = Subscription.new
      subscription.account_id=options[:account_id]
      subscription.tariff_plan_id = options[:tariff_plan]
      subscription.quantity = options[:quantity]


      # Set tariff-related fields
      tariff = @all_tariff_plans[subscription.tariff_plan_id]
      raise ArgumentError, 'Invalid tariff given: %s' % subscription.tariff_plan_id if tariff.nil?
      subscription.currency = tariff["currency"]
      subscription.periodicity = tariff["payment_term"]["periodicity"]

      subscription.starts_on = options[:start_date] + tariff["payment_term"]["trial_days"]
      subscription.ends_on = options[:end_date]

      # Set tax- and payment-related fields
      subscription.taxes_id = get_applicable_taxes_id(options[:account_country], options[:account_state])
      total_tax = @all_taxes[subscription.taxes_id]["taxes"].inject(0){|sum,item| sum + item["rate"]}   # sum all taxes
      subscription.net_amount = subscription.quantity * tariff["price"]
      subscription.taxes_amount = subscription.net_amount * total_tax

      subscription.status = 'pending'
      subscription.save

      return subscription.id
    end

    # Proceed subscription payment through specified payment gateway
    def pay_for_subscription(subscription_id, card, payment_options)
      subscription = Subscription.find_by_id(subscription_id)

      gw = RecurringBilling::RecurringBillingGateway.get_instance(@gateway)
      tariff = @all_tariff_plans[subscription.tariff_plan_id]
      recurring_options = {
              :start_date => subscription.starts_on,
              :trial_days => tariff['payment_term']['trial_days'],
              :end_date => subscription.ends_on,
              :interval => tariff['payment_term']['periodicity']
              }

      if payment_options[:subscription_name].nil?
        payment_options[:subscription_name] = @tariff_plans_namespace+': '+tariff['service']['name']
      end

      payment_options[:taxes_amount_included] = Money.new(subscription.taxes_amount,subscription.currency)

      gateway_id = gw.create(Money.new(subscription.billing_amount, subscription.currency), card, payment_options, recurring_options)
      if !gateway_id.nil?
        sp = SubscriptionProfile.new
        sp.subscription_id = subscription.id
        sp.recurring_payment_profile_id = RecurringPaymentProfile.find_by_gateway_reference(gateway_id).id
        sp.save
        subscription.status = 'ok'
        subscription.save
      else
        raise StandardError, 'Recurring payment creation error: ' + gw.last_response.message
      end
    end

    # Update subscription through specified payment gateway
    def update_subscription(subscription_id, options)
      profile = get_active_profile(subscription_id)
      gw = RecurringBilling::RecurringBillingGateway.get_instance(@gateway)
      unless new_gateway_reference = gw.update_or_recreate(profile.gateway_reference, options)
        raise StandardError, 'Cannot update subscription through gateway: ' + gw.last_response.message
      end

      unless new_gateway_reference == profile.gateway_reference
        sp = SubscriptionProfile.new
        sp.subscription_id = subscription_id
        sp.recurring_payment_profile_id = RecurringPaymentProfile.find_by_gateway_reference(new_gateway_reference).id
        sp.save
      end
    end

    # Gets active profile for given subscription_id
    def get_active_profile(subscription_id)
      raise StandardError, "Subscription with ID #{subscription_id} not found" if (subscription = Subscription.find_by_id(subscription_id)).nil?
      raise StandardError, "Subscription with ID #{subscription_id} is inactive and cannot thus have active profiles" unless subscription.status == 'ok'

      if (profile = subscription.recurring_payment_profiles.find(:first, :conditions => [ "status != 'deleted'"])).nil?
        raise StandardError, "Cannot find any active profiles for subscription: #{subscription_id}"
      end

      return profile
    end

    # Checks if given subscription could be updated (re-create would be needed otherwize)
    def update_possible?(subscription_id, options)
      begin
        gw = RecurringBilling::RecurringBillingGateway.get_instance(@gateway)
        return gw.can_update?(get_active_profile(subscription_id).gateway_reference, options) ? true : false
      rescue
        return false
      end
    end

    #Cancel subscription (specified by SUBSCRIPTION_ID)
    def unsubscribe(subscription_id)
       raise StandardError, "Subscription with ID #{subscription_id} not found" if (subscription = Subscription.find_by_id(subscription_id)).nil?
       if subscription.status == 'ok' && !(profile = subscription.recurring_payment_profiles.find(:first, :conditions => [ "status != 'deleted'"])).nil?
          gw = RecurringBilling::RecurringBillingGateway.get_instance(@gateway)
          raise StandardError, 'Cannot cancel subscription through gateway: ' + gw.last_response.message unless gw.delete(profile.gateway_reference)
       end
       subscription.status = 'canceled'
       subscription.save
    end

    #Get available features provided by given subscription (specified by SUBSCRIPTION_ID)
    def get_features(subscription_id)
      return {} if (subscription = Subscription.find_by_id(subscription_id)).nil? && (subscription.status != 'ok')
      @all_tariff_plans[subscription.tariff_plan_id]['service']['features']
    end

    def get_invoice_data(invoice_id) #:nodoc:
      transaction = Transaction.find invoice_id
      profile = transaction.recurring_payment_profile

      if transaction.money != profile.money
        raise NotImplementedError, 'Transaction payment cannot differ from recurring payment'
      end

      subscription = SubscriptionProfile.find(:first, :conditions => ['recurring_payment_profile_id = ?', profile]).subscription
      tariff = @all_tariff_plans[subscription.tariff_plan_id]
      service_name = '%s %s(%s)' % [
        tariff['service']['name'],
        (subscription.quantity == 1 ? '' : 'x%s '% subscription.quantity),
        SubscriptionManagement.format_periodicity(tariff['payment_term']['periodicity']).gsub('each','per')
        ]
      {
        :billing_account => subscription.account_id,
        :service_name => service_name,
        :net_amount => profile.net_money_formatted,
        :taxes_amount => profile.taxes_money_formatted,
        :total_amount => profile.money_formatted,
        :taxes_comment => @all_taxes[subscription.taxes_id]["name"],

        :date => transaction.created_at,
        :number => transaction.id,
        :transaction_gateway => profile.gateway,
        :transaction_id => transaction.gateway_reference,
        :transaction_amount => transaction.money_formatted
      }
    end

    class << self

      # Returns whole contents of given tariff config file (by CONFIG_NAME filename)
      def read_tariff_config(config_name)
        return YAML.load([File.read('%s/presets.yml' % File.dirname(config_name)), File.read(config_name)].join("\n"))
      end

      # Retrieves tariff settings from given file (by CONFIG_NAME filename)
      def get_all_tariff_plans(config_name)
        return read_tariff_config(config_name)[File.basename(config_name, '.yml')]['tariff_plans']
      end

      # Reads tax config from given file (by CONFIG_NAME filename)
      def get_all_taxes(config_name)
        return YAML.load(File.read(config_name))['taxes']
      end

      # Reads gateway settings from given file (by CONFIG_NAME filename)
      def get_gateway_settings(config_name)
        def symbolize_keys(hash)
          return unless hash.is_a?(Hash)

          hash.symbolize_keys!
          hash.each{|k,v| symbolize_keys(v)}
        end

        symbolize_keys(YAML.load(File.read(config_name)))
      end

      # Returns the most applicable identifier of tax area settings available for given COUNTRY and STATE (class)
      # 
      # Example:
      #  taxes = {}
      #  taxes["ca"] = {"country"=>"CA", "taxes"=>[{"tax"=>{"name"=>"Tax1"}, "rate"=>0.05}], "state"=>"*"}
      #  taxes[""us_ca""] = {"country"=>"US", "taxes"=>[{"tax"=>{"name"=>"Sample tax"}, "rate"=>0.2}], "state"=>"CA"}
      #  get_taxes_id(taxes, 'RU', 'MSK') # => StandardError
      #  get_taxes_id(taxes, 'CA', 'ON') # => "ca"
      #  get_taxes_id(taxes, 'US', 'CA') # => "us_ca"
      #  get_taxes_id(taxes, 'US', 'FL') # => StandardError
      def get_taxes_id(taxes, country, state)
        return ("%s_%s" % [country, state]).downcase unless (state.empty? || taxes[("%s_%s" % [country, state]).downcase].nil?)
        return country.downcase unless (country.empty? || taxes[country.downcase].nil?)
        raise StandardError, 'Tax is unknown for given country and state -  %s, %s' % [country, state]
      end

      # Returns formatted string for FEATURE hash
      #
      # Example 1:
      # feature['feature']['name'] = 'Message Boards'
      # feature['quantity'] == nil => 'Message Boards' (when we just want to show that feature is available)
      # feature['quantity'] == 1, feature['feature']['unit'] == nil => 'Message Boards: 1' (when unit is obvious from feature name)
      #
      # Example 2:
      # feature['feature']['name'] = 'Disk Quota'
      # feature['quantity'] == 1, feature['feature']['unit'] == 'Gigabyte' => 'Disk Quota: 1 Gigabyte' (when unit is not obvious it has to be specified)
      # feature['quantity'] == 2, feature['feature']['unit'] == 'Gigabyte' => 'Disk Quota: 2 Gigabytes'
      # feature['quantity'] == 0, feature['feature']['unit'] == 'Gigabyte' => 'Disk Quota: Unlimited'
      def format_feature(feature)
        return "#{feature['feature']['name']}" unless feature['quantity']
        quantity = feature['quantity']
        if quantity == 0
          return "#{feature['feature']['name']}: Unlimited"
        else
          return "#{feature['feature']['name']}: #{quantity}" unless feature['feature']['unit']
          unit_correct_form = (quantity > 1) ? ActiveSupport::Inflector.pluralize(feature['feature']['unit']) : feature['feature']['unit']
          return "#{feature['feature']['name']}: #{quantity} #{unit_correct_form}"
        end
      end

      # Returns human-readable string for standard interval string (PERIODICITY)
      #
      # Sample use:
      #  "1w" => 'each week'
      #  "0.5 m" => 'twice a month'
      #  "10 d" => 'each 10 days'
      #  "3y" => 'each 3 years'
      #  "0.25 w" => ArgumentError
      #  "2 x" => ArgumentError
      def format_periodicity(periodicity)
        if (periodicity =~ /^(\d+|0\.5)\s*(d|w|m|y)$/i)
          i_length, i_unit = $1 == '0.5' ? 0.5 : $1.to_i, $2.downcase.to_sym
        else
          raise ArgumentError, "Invalid periodicity given: #{periodicity}"
        end

        text_unit =  case i_unit
                          when :d then 'day'
                          when :w then 'week'
                          when :m then 'month'
                          when :y then 'year'
                        end

        return "twice a #{text_unit}" if i_length == 0.5
        return "each #{text_unit}" if i_length == 1
        return "each #{i_length} #{ActiveSupport::Inflector.pluralize(text_unit)}"
      end

    end
  end
#end
