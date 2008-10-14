module RecurringBilling
  class AuthorizeNetGateway < RecurringBillingGateway
    include Utils

    def code
      :authorize_net
    end

    def name
      'Authorize.net'
    end

    # Check if update is possible using specified arguments
    def correct_update?(billing_id, amount, card, payment_options, recurring_options)
      if !recurring_options.nil? && recurring_options.length > 0
        raise StandardError, 'Cannot update recurring options at #{name} gateway'
      end
      return true
    end

    # Make an update using gateway-specific actions
    def update_specific(billing_id, amount, card, payment_options, recurring_options)
      options = compile_options(amount, card, payment_options, recurring_options)
      options[:amount] = amount
      options[:subscription_id] = billing_id
      (@last_response = @gateway.update_recurring(options)).success?
    end

    # Create payment using gateway-specific actions
    def create_specific(amount, card, payment_options, recurring_options)
      @last_response = @gateway.recurring(amount, card, compile_options(amount, card, payment_options, recurring_options))
      return @last_response.authorization if @last_response.success?
      nil
    end

    # Cancel the subscription
    def delete_specific(billing_id)
      (@last_response = @gateway.cancel_recurring(billing_id)).success?
    end

    # Get ready-to-send options hash
    def compile_options(amount, card, payment_options, recurring_options)
      new_options = {}
      if !recurring_options.nil? && !recurring_options.empty?
        requires!(recurring_options, :start_date, :interval)
        requires!(recurring_options, :occurrences) unless recurring_options.has_key?(:end_date)
        requires!(recurring_options, :end_date) unless recurring_options.has_key?(:occurrences)
        transformed_dates = (recurring_options[:occurrences]) ?
                             transform_dates(recurring_options[:start_date], recurring_options[:interval], recurring_options[:occurrences], nil) :
                             transform_dates(recurring_options[:start_date], recurring_options[:interval], nil, recurring_options[:end_date])

        new_options = {:interval => transformed_dates[:interval], :duration => transformed_dates[:duration]}
      end

      billing_address = payment_options.has_key?(:billing_address) ? payment_options[:billing_address] : {}
      if (!billing_address.has_key?(:last_name) || billing_address[:last_name].empty?) && card
        billing_address[:last_name] = card.last_name
        billing_address[:first_name] = card.first_name
      end


      new_options[:billing_address] = billing_address
      new_options[:subscription_name] = payment_options[:subscription_name] if payment_options.has_key?(:subscription_name)
      new_options[:order] = payment_options[:order] if payment_options.has_key?(:order)

      return new_options

    end

    #Transform dates to Authorize.net-recognizable format
    def transform_dates(start_date, interval, occurrences, end_date)

      raise ArgumentError, 'Either number of occurences OR end date should be specified' if (!occurrences.nil? && !end_date.nil?) || ((occurrences.nil? && end_date.nil?))
      raise ArgumentError, 'Payment cycle start date ({#start_date}) should be less than or equal to end date ({#end_date})' if !end_date.nil? && (start_date>end_date)
      raise ArgumentError, 'Number of payment occurrences should be a positive integer)' if !occurrences.nil? && (occurrences <= 0)

      i_length, i_unit = parse_interval(interval)

      if i_length == 0.5 && (i_unit != :y)
        raise ArgumentError, "Semi- interval is not supported to this units (#{i_unit.to_s})"
      end

      new_interval =  case i_unit
                        when :d then {:length=>i_length,    :unit=>:days}
                        when :w then {:length=>i_length*7,  :unit=>:days}
                        when :m then {:length=>i_length,    :unit=>:months}
                        when :y then {:length=>i_length*12, :unit=>:months}
                      end
      if !occurrences.nil?
        return {:interval=>new_interval, :duration=>{:start_date=>start_date, :occurrences=>occurrences}}
      else
        if new_interval[:unit] == :days
          new_occurrences = 1 + ((end_date - start_date)/new_interval[:length]).to_i
        elsif new_interval[:unit] == :months
          new_occurrences = 1 + (months_between(end_date, start_date)/new_interval[:length]).to_i
        end
        return {:interval=>new_interval, :duration=>{:start_date=>start_date, :occurrences=>new_occurrences}}
      end
    end


  end
end
