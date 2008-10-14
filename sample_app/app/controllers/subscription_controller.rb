class SubscriptionController < ApplicationController

  def initialize
    super
    # sample data, would be replaced with authentication system
    @current_account = {:first_name => 'John', :last_name => 'Smith', :id => 'Test', :country => 'US', :state => 'CA'}
    @sm = SubscriptionManager
  end

  def index
    @active_subscriptions = Subscription.find(:all, :conditions => ['account_id = ? and status = ?', @current_account[:id], 'ok'])
    @inactive_subscriptions = Subscription.find(:all, :conditions => ['account_id = ? and status not in (?)', @current_account[:id], ['ok','pending']])
  end

  def show
    @subscription = Subscription.find(params[:id])
    @tariff_plan = @sm.all_tariff_plans[@subscription.tariff_plan_id]
  end

  def subscribe
    if !params[:submit].nil? && !params[:tariff_plan_id].nil?
      subscription_options = {
          :account_id => @current_account[:id],
          :account_country => @current_account[:country],
          :account_state => @current_account[:state],
          :tariff_plan => params[:tariff_plan_id],
          :quantity => params[:quantity].to_i,
          :start_date => Date.parse(params[:start_date]),
          :end_date => Date.parse(params[:end_date])
        }
      credit_card = ActiveMerchant::Billing::CreditCard.new({
          :type => params[:card_type],
          :number => params[:card_number].to_i,
          :month => params[:card_expiration_month].to_i,
          :year => params[:card_expiration_year].to_i,
          :first_name => params[:card_first_name],
          :last_name => params[:card_last_name],
          :verification_value => params[:card_verification_value]
      })
      # subscribe
      subscription_id = @sm.subscribe(subscription_options)

      # this block should be different in multi-step subscription
      begin
        @sm.pay_for_subscription(subscription_id, credit_card, {})
      rescue
        Subscription.delete(subscription_id)
        raise
      end

      redirect_to :action => nil
      return
    end
  end

  def unsubscribe
    @subscription = Subscription.find(params[:id])
    if !params[:submit].nil?
      @sm.unsubscribe(@subscription.id)
      redirect_to :action => nil
      return
    end
  end

  def update_card
    @subscription = Subscription.find(params[:id])
    if !params[:submit].nil?
      credit_card = ActiveMerchant::Billing::CreditCard.new({
          :type => params[:card_type],
          :number => params[:card_number].to_i,
          :month => params[:card_expiration_month].to_i,
          :year => params[:card_expiration_year].to_i,
          :first_name => params[:card_first_name],
          :last_name => params[:card_last_name],
          :verification_value => params[:card_verification_value]
      })
      @sm.update_subscription(@subscription.id, {:card => credit_card})
      redirect_to :action => 'show', :id => @subscription.id
      return
    end
  end

  def invoice

    if params[:id] == 'sample'
      data = {
        :billing_account => @current_account[:id],

        # Subscription
        :service_name => 'Basic (per month)',
        :net_amount => '89.90 USD',
        :taxes_amount => '10.00 USD',
        :taxes_comment => 'resident', # nullable
        :total_amount => '99.90 USD',

        # Payment
        :date => Date.today,                    # payment.created_at
        :number => 9999,                        # payment.id
        :transaction_gateway => 'PayPal',
        :transaction_id => 'XYZ123456789CBA',
        :transaction_amount => '99.90 USD'
        }
    else
      data = @sm.get_invoice_data(params[:id])
    end

    # FILLED BY APPLICATION
    data[:billing_address] = "44 Highway st., #33\nWashington, DC 99999-1111\nUSA"
    data[:billing_name] = "%s %s" % [@current_account[:first_name], @current_account[:last_name]]

    # APPLICATION preferences
    data[:date_format] = '%Y-%m-%d' # nullable

    # PDF generation
    data[:date_format] = '%Y/%m/%d' if data[:date_format].nil?
    data.each {|name, value| instance_variable_set('@invoice_'+name.to_s, value)}
    #render :action => 'invoice.rpdf', :layout => false
    send_data render_to_pdf({ :action => 'invoice.rpdf', :layout => false }), {:type => :pdf, :filename => "invoice_%s.pdf" % data[:number]}
  end

end
