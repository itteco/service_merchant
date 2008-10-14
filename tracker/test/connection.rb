# As we're not using Rails in tests, we have to establish DB conneciton ourselves
require 'rubygems'
gem 'activerecord'
require 'activerecord'
gem 'sqlite3-ruby'

ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3",
    :database  => (File.dirname(__FILE__) + "/../db/test.db")
)
