class AdminController < ApplicationController
  layout 'admin'

  def initialize
    super
    @sm = SubscriptionManager
  end


  def index
  end

  def tariff_plan
    @tariff_plan = @sm.all_tariff_plans[params[:id]]
    @active_subscriptions = Subscription.find(:all, :conditions => ['tariff_plan_id = ? and status = ?', params[:id], 'ok'])
    @inactive_subscriptions = Subscription.find(:all, :conditions => ['tariff_plan_id = ? and status not in (?)', params[:id], ['ok','pending']])
  end

  def problem_subscriptions
    @subscriptions = Subscription.find(:all, :conditions => "0 < (select count(*) from subscription_profiles sp, tracker_recurring_payment_profiles tp where tp.problem_status is not null and tp.problem_status !='' and tp.id = sp.recurring_payment_profile_id and sp.subscription_id = subscriptions.id)")
  end

  def problem_subscription
    @subscription = Subscription.find(params[:id])
    @tariff_plan = @sm.all_tariff_plans[@subscription.tariff_plan_id]
  end

end
