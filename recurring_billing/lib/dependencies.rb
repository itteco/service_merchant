require 'rubygems'

gem 'activemerchant'
require 'active_merchant'

#TODO: Autodiscover new libs from vendor and add them to load path
$: << File.dirname(__FILE__) + "/../../vendor/money-1.7.1/lib"
require "money"

gem 'activesupport'
require 'active_support/core_ext/string/inflections'
class String # :nodoc:
  include ActiveSupport::CoreExtensions::String::Inflections
end
