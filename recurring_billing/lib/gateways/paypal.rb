module RecurringBilling
  class PaypalGateway < RecurringBillingGateway
    include Utils
    
    # Returns :paypal
    def code
      :paypal
    end

    # Returns 'PayPal Website Payments Pro (US)'
    def name
      'PayPal Website Payments Pro (US)'
    end

    # Checks whether passed parameters of requested recurring payment conform to specification
    def correct_create?(amount, card, payment_options, recurring_options)
      raise ArgumentError, 'Ammount must be defined and more than zero' if amount.nil? || amount.zero?
      raise ArgumentError, 'Card is mandatory' if card.nil? # must be object of CreditCard class
      raise ArgumentError, 'Subscription name is mandatory' if payment_options[:subscription_name].to_s.empty?
      raise ArgumentError, 'Starting date is mandatory' if recurring_options[:start_date].to_s.empty?
      raise ArgumentError, 'Interval is mandatory' if recurring_options[:interval].to_s.empty?
      # end_date and occurrences - both can be ommited
      return true
    end


    # Checks if update is possible using specified arguments
    def correct_update?(billing_id, amount, card, payment_options, recurring_options)
      raise ArgumentError, 'Billing ID is mandatory' if billing_id.to_s.empty?
      raise ArgumentError, 'Starting date cannot be updated' if !recurring_options[:start_date].to_s.empty?
      raise ArgumentError, 'Interval cannot be updated' if !recurring_options[:interval].to_s.empty?

      if !(recurring_options[:end_date].to_s.empty? && recurring_options[:occurrences].to_s.empty?)
        raise NotImplementedError, 'Cannot shift the end of recurring payment'
        # it is made via "AdditionalBillingCycles", so we have to know previous data
      end
      return true
    end

    # Create payment using gateway-specific actions
    def create_specific(amount, card, payment_options, recurring_options)
      @last_response = @gateway.recurring(amount, card, convert_options(payment_options, recurring_options))
      return @last_response.params['profile_id'] if @last_response.success?
      nil
    end

    # Make an update using gateway-specific actions
    def update_specific(billing_id, amount, card, payment_options, recurring_options)
      options = convert_options(payment_options, recurring_options)
      options[:profile_id] = billing_id
      (@last_response = @gateway.recurring(amount, card, options)).success?
    end

    # Cancel the subscription
    # TODO: Add :note parameter to API to enable it in update and cancel
    def delete_specific(billing_id)
      (@last_response = @gateway.cancel_recurring(billing_id, {})).success?
    end

    # TODO: Unify result parameters names and values
    def inquiry_specific(billing_id)
      @last_response = @gateway.inquiry_recurring(billing_id)
      result = @last_response.params.clone

      result.each do |k,v|
        if k =~ /(^number_|_count$|_cycles(_|$)|_payments$|_frequency$|_month$|_year$)/
          result[k] = v.to_i
        elsif k =~ /(_date|^timestamp)$/
          result[k] = DateTime.parse(v)
        elsif (k =~ /(_|^)amount(_paid)?$/ && k != 'auto_bill_outstanding_amount') || k =~ /_balance$/
          currency = result[k+'_currency_id']
          result[k] = Money.new(v.to_f*100, currency=currency) # dollars => cents
        elsif k =~ /_(status|period|card_type)$/
          result[k] = v.downcase
        end
      end

      result['profile_status'] =~ /^(.*)Profile$/i
      result['profile_status'] = $1 # active | pending | cancelled | suspended | expired

      return result.reject {|k,v| k =~ /_currency_id$/}
    end


    def convert_options(payment_options, recurring_options)
      options = {}
      options[:billing_address] = payment_options[:billing_address] if !payment_options[:billing_address].nil?
      options[:description] = payment_options[:subscription_name]
      options[:starting_at] = recurring_options[:start_date]
      options[:total_payments] = recurring_options[:occurrences] if !recurring_options[:occurrences].nil?
      options[:interval] = convert_interval(recurring_options[:interval]) if !recurring_options[:interval].nil? # absent for update
      options[:currency] = payment_options[:currency] if !payment_options[:currency].nil?
      #options[:note] = payment_options[:note] if !payment_options[:note].nil?
      return options
    end


    def convert_interval(interval)
      i_length, i_unit = parse_interval(interval)

      if i_length == 0.5 && ![:m,:y].include?(i_unit)
        raise ArgumentError, "Semi- interval is not supported to this units (#{i_unit.to_s})"
      end

      if    [i_length, i_unit] == [0.5, :m]
        return {:length => 1, :unit => 'SemiMonth'}
      elsif [i_length, i_unit] == [0.5, :y]
        i_length, i_unit = [6, :m]
      end

      return {:length => i_length, :unit => convert_unit(i_unit)}
    end

    def convert_unit(unit)
      return  case unit
                when :d then 'Day'
                when :w then 'Week'
                when :m then 'Month'
                when :y then 'Year'
              end
    end

  end
end
