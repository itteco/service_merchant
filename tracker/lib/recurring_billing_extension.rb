require File.dirname(__FILE__) + '/../../recurring_billing/lib/recurring_billing'

module RecurringBilling
  class RecurringBillingGateway

    # Create recurring payment AND store it
    def create_with_persist(amount, card, payment_options={}, recurring_options={})
      if payment_id = create_without_persist(amount, card, payment_options, recurring_options)
        profile = RecurringPaymentProfile.new
        profile.gateway_reference = payment_id
        profile.gateway = code().to_s.upcase
        profile.subscription_name = payment_options[:subscription_name]

        # Split amount into net/taxes
        if payment_options.has_key?(:taxes_amount_included)
          profile.net_money = amount - payment_options[:taxes_amount_included]
          profile.taxes_money = payment_options[:taxes_amount_included]
          payment_options.delete(:taxes_amount_included)
        else
          profile.net_money = amount
          profile.taxes_amount = 0
        end

        profile.parse_and_set_card(card)
        ro = recurring_options
        profile.trial_days = trial_days = ro[:trial_days].nil? ? 0 : ro[:trial_days].to_i
        profile.pay_on_day_x = ro[:pay_on_day_x] unless ro[:pay_on_day_x].nil?
        start_date = ro[:start_date] - trial_days
        if get_midnight(start_date) == get_midnight(DateTime.now)
          profile.created_at = start_date
        else
          profile.created_at = get_midnight(start_date)
        end
        profile.periodicity = '%d %s' % parse_interval(ro[:interval])
        if ro[:occurrences].nil?
          profile.total_payments_count = get_occurrences(ro[:start_date] - trial_days, ro[:interval], ro[:end_date])
        else
          profile.total_payments_count = ro[:occurrences]
        end
        profile.set_profile_active_and_save!
        return payment_id
      end
    end
    alias_method_chain :create, :persist

    # Update recurring payment AND its local info
    def update_with_persist(billing_id, amount, card, payment_options={}, recurring_options={})
      profile = RecurringPaymentProfile.find_by_gateway_reference(billing_id)
      #TODO: change to custom error
      raise StandardError, 'Cannot update a deleted profile (#{billing_id})' if profile.status == 'deleted'

      if update_without_persist(billing_id, amount, card, payment_options, recurring_options)
        profile.set_profile_after_update!(amount, card, payment_options, recurring_options)
        return true
      end
    end
    alias_method_chain :update, :persist

    # Inquire about recurring payment AND update its info
    def inquiry_with_persist(billing_id)
      result = inquiry_without_persist(billing_id)
      RecurringPaymentProfile.find_by_gateway_reference(billing_id).set_profile_after_inquiry!(result)
      return result
    end
    alias_method_chain :inquiry, :persist

    # Cancel recurring payment AND update its info
    def delete_with_persist(billing_id)
      if delete_without_persist(billing_id)
        RecurringPaymentProfile.find_by_gateway_reference(billing_id).mark_as_deleted!
        return true
      end
    end
    alias_method_chain :delete, :persist

    # Tells if update or recreate is needed
    def can_update?(billing_id, options)
      begin
        options = self.class.separate_create_update_params_from_options(options)
        can_update = correct_update?(billing_id, options[:amount], options[:card], options[:payment_options], options[:recurring_options])
      rescue Exception
        can_update = false
      end
    end

    # Updates or if updating is impossible, recreates profile with specified billing_id
    def update_or_recreate(billing_id, options)
      if can_update?(billing_id, options)
        options_separated = self.class.separate_create_update_params_from_options(options)
        update(billing_id, options_separated[:amount], options_separated[:card], options_separated[:payment_options], options_separated[:recurring_options])
        return billing_id
      else
        RecurringPaymentProfile.find_by_gateway_reference(billing_id).update_options_from_profile!(options)
        options_separated = self.class.separate_create_update_params_from_options(options)
        correct_create?(options_separated[:amount], options_separated[:card], options_separated[:payment_options], options_separated[:recurring_options])
        delete(billing_id)
        return create(options_separated[:amount], options_separated[:card], options_separated[:payment_options], options_separated[:recurring_options])
      end
      nil
    end

  end
end
