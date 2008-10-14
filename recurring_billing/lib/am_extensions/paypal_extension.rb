module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PaypalGateway < Gateway#:nodoc:

      # this file was originally located in activemerchant-1.3.2/lib/active_merchant/billing/gateways
      # MANUAL https://www.paypal.com/en_US/pdf/PP_APIReference.pdf
      # See also:
      #   http://jadedpixel.lighthouseapp.com/projects/11599/tickets/17-patch-creating-paypal-recurring-payments-profile-with-activemerchant

      remove_const("RECURRING_ACTIONS") if defined? RECURRING_ACTIONS
      RECURRING_ACTIONS = Set.new([:add, :modify, :cancel, :inquiry])

      # :interval - cannot exceed 1 year
      # :interval[:unit] = :week | :semimonth | :month | :year

      def recurring(money, credit_card, options = {})
        options[:name] = credit_card.name if options[:name].blank? && credit_card
        request = build_recurring_request(options[:profile_id].nil? ? :add : :modify, money, options) do |xml|
          add_credit_card(xml, credit_card, options[:billing_address], options) if credit_card
        end
        commit options[:profile_id].nil? ? 'CreateRecurringPaymentsProfile' : 'UpdateRecurringPaymentsProfile', request
      end

      def cancel_recurring(profile_id, options)
        request = build_recurring_request(:cancel, nil, options.update( :profile_id => profile_id ))
        commit 'ManageRecurringPaymentsProfileStatus', request
      end

      def inquiry_recurring(profile_id, options = {})
        request = build_recurring_request(:inquiry, nil, options.update( :profile_id => profile_id ))
        commit 'GetRecurringPaymentsProfileDetails', request
      end

      private

      def build_recurring_request(action, money, options)
        unless RECURRING_ACTIONS.include?(action)
          raise StandardError, "Invalid Recurring Profile Action: #{action}"
        end

        xml = Builder::XmlMarkup.new :indent => 2

        if action == :add
          xml.tag! 'CreateRecurringPaymentsProfileReq', 'xmlns' => PAYPAL_NAMESPACE do
            xml.tag! 'CreateRecurringPaymentsProfileRequest', 'xmlns:n2' => EBAY_NAMESPACE do
              xml.tag! 'n2:Version', 50.0 # API_VERSION  # must be >= 50.0
              xml.tag! 'n2:CreateRecurringPaymentsProfileRequestDetails' do

                yield xml   # put card information : CreditCardDetails


                xml.tag! 'n2:RecurringPaymentsProfileDetails' do
                  xml.tag! 'n2:BillingStartDate', format_date(options[:starting_at])
                  # SubscriberName (optional)
                  # SubscriberShippingAddress (optional)
                  # ProfileReference (optional) = The merchant’s own unique reference or invoice number.
                end

                xml.tag! 'n2:ScheduleDetails' do
                  xml.tag! 'n2:Description', options[:description] # <= 127 single-byte alphanumeric characters!!!
                    # This field must match the corresponding billing agreement description included in the SetExpressCheckout reques
                  # ? MaxFailedPayments
                  # ? AutoBillOutstandingAmount = NoAutoBill / AddToNextBilling

                  xml.tag! 'n2:PaymentPeriod' do
                    # if == :semimonth, then payed at 1 & 15 day of month
                    xml.tag! 'n2:BillingFrequency', options[:interval][:length]
                    xml.tag! 'n2:BillingPeriod', format_unit(options[:interval][:unit])
                    xml.tag! 'n2:Amount', amount(money), 'currencyID' => options[:currency] || currency(money)
                    # ShippingAmount (optional)
                    # TaxAmount (optional)
                    xml.tag! 'n2:TotalBillingCycles', options[:total_payments].to_s unless options[:total_payments].nil?
                  end

                  # WARNING: Activation not tested
                  unless options[:activation].nil?
                    xml.tag! 'n2:ActivationDetails' do
                      xml.tag! 'n2:InitialAmount', amount(options[:activation][:amount]), 'currencyID' => options[:currency] || currency(options[:activation][:amount])
                      xml.tag! 'n2:FailedInitAmountAction', options[:activation][:failed_action] unless options[:activation][:failed_action] # 'ContinueOnFailure/CancelOnFailure'
                      xml.tag! 'n2:MaxFailedPayments', options[:activation][:max_failed_payments].to_s unless options[:activation][:max_failed_payments].nil?
                    end
                  end

                  # WARNING: trial option not tested
                  unless options[:trial].nil?
                    xml.tag! 'n2:TrialPeriod' do
                      frequency, period = get_pay_period(options[:trial][:periodicity])
                      xml.tag! 'n2:BillingFrequency', frequency.to_s
                      xml.tag! 'n2:BillingPeriod', period
                      xml.tag! 'n2:Amount', amount(options[:trial][:amount]), 'currencyID' => options[:currency] || currency(options[:trial][:amount])
                      xml.tag! 'n2:TotalBillingCycles', options[:trial][:total_payments].to_s
                    end
                  end

                end
              end
            end
          end

        elsif action == :modify
          xml.tag! 'UpdateRecurringPaymentsProfileReq', 'xmlns' => PAYPAL_NAMESPACE do
            xml.tag! 'UpdateRecurringPaymentsProfileRequest', 'xmlns:n2' => EBAY_NAMESPACE do
              xml.tag! 'n2:Version', 50.0 # API_VERSION  # must be >= 50.0
              xml.tag! 'n2:UpdateRecurringPaymentsProfileRequestDetails' do

                xml.tag! 'n2:ProfileID', options[:profile_id]
                xml.tag! 'n2:Note', options[:note] unless options[:note].nil?
                xml.tag! 'n2:Description', options[:description] unless options[:description].nil? # <= 127 single-byte alphanumeric characters!!!

                # SubscriberName (optional)
                # SubscriberShippingAddress (optional)
                # ProfileReference (optional) = The merchant’s own unique reference or invoice number.
                xml.tag! 'n2:AdditionalBillingCycles', options[:additional_payments].to_s unless options[:additional_payments].nil?
                xml.tag! 'n2:Amount', amount(money), 'currencyID' => options[:currency] || currency(money) unless money.nil?
                # ShippingAmount (optional)
                # TaxAmount (optional)
                # OutStandingBalance (optional)
                  # The current past due or outstanding amount for this profile. You can only
                  # decrease the outstanding amount—it cannot be increased.
                # ? AutoBillOutstandingAmount (optional) = NoAutoBill / AddToNextBilling
                # ? MaxFailedPayments (optional) = The number of failed payments allowed before the profile is automatically suspended.

                yield xml   # put card information : CreditCardDetails
                  # Only enter credit card details for recurring payments with direct payments.
                  # Credit card billing address is optional, but if you update any of the address
                  # fields, you must enter all of them. For example, if you want to update the
                  # street address, you must specify all of the address fields listed in
                  # CreditCardDetailsType, not just the field for the street address.
              end
            end
          end

         elsif action == :cancel
          xml.tag! 'ManageRecurringPaymentsProfileStatusReq', 'xmlns' => PAYPAL_NAMESPACE do
            xml.tag! 'ManageRecurringPaymentsProfileStatusRequest', 'xmlns:n2' => EBAY_NAMESPACE do
              xml.tag! 'n2:Version', 50.0
              xml.tag! 'n2:ManageRecurringPaymentsProfileStatusRequestDetails' do
                xml.tag! 'n2:ProfileID', options[:profile_id]
                xml.tag! 'n2:Action', 'Cancel'
                xml.tag! 'n2:Note', options[:note] unless options[:note].nil?
              end
            end
          end

        elsif action == :inquiry
          xml.tag! 'GetRecurringPaymentsProfileDetailsReq', 'xmlns' => PAYPAL_NAMESPACE do
            xml.tag! 'GetRecurringPaymentsProfileDetailsRequest', 'xmlns:n2' => EBAY_NAMESPACE do
              xml.tag! 'n2:Version', 50.0
              xml.tag! 'ProfileID', options[:profile_id]
            end
          end
        end
      end

      def format_date(dat)
        case dat.class.to_s
          when 'Date' then return dat.strftime('%FT%T')
          when 'Time' then return dat.getgm.strftime('%FT%T')
          when 'String' then return dat
        end
      end

      def format_unit(unit)
        requires!({:data => unit}, [:data, 'Week', 'SemiMonth', 'Month', 'Year'])
        unit.to_s.downcase.capitalize
      end

    end
  end
end
