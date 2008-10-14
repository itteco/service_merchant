#!/usr/bin/env ruby
# This is a smoke test for Tracker component

require 'tracker'
puts "Verifying models classes..."
Transaction
RecurringPaymentProfile
puts "Verifying DB..."
require 'test/connection'
Transaction.count
RecurringPaymentProfile.find :first
puts "All OK"
