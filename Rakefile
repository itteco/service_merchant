require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
#require 'rake/contrib/rubyforgepublisher'

PKG_VERSION = "0.1.0"
PKG_NAME = "service_merchant"
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

PKG_FILES = FileList[
    "recurring_billing/**/*", "subscription_management/**/*", "tracker/**/*", "[a-zA-Z]*"
].exclude(/\.svn$/)

task :default => 'dobuild'

task :install => [:package] do
  `gem install pkg/#{PKG_FILE_NAME}.gem`
end

#TODO: use defaults in task
task :test => ["test:default"] do
  puts 'All tests run is complete.'
end

task :dobuild => [:test, :gem] do
  puts 'Build complete'
end

# Genereate the RDoc documentation
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = "ServiceMerchant library"
  rdoc.options << '--line-numbers' << '--inline-source' << '--main=README' << '--include=tracker/lib/'
  rdoc.rdoc_files.include('README.txt')
  rdoc.rdoc_files.include('recurring_billing/lib/**/*.rb')
  rdoc.rdoc_files.include('subscription_management/lib/**/*.rb')
  rdoc.rdoc_files.include('tracker/lib/**/*.rb')
end

desc "Delete tar.gz / zip / rdoc"
task :cleanup => [ :clobber_package ]

spec = Gem::Specification.new do |s|
  s.name = PKG_NAME
  s.version = PKG_VERSION
  s.summary = "Provides UI and tools to add billing feature to web application"
  s.has_rdoc = true

  s.files = PKG_FILES

  s.add_dependency('activemerchant', '= 1.3.2')
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

#######################################################################

require File.dirname(__FILE__)+'/tracker/tasks/schema'
require File.dirname(__FILE__)+'/subscription_management/tasks/schema'

desc "Create all tables"
task :create_all_tables => ["tracker:create_tables", "subscription:create_tables"]

desc "Drop all tables"
task :drop_all_tables => ["subscription:drop_tables", "tracker:drop_tables"]

# Run the tests
namespace :test do
  Rake::TestTask.new(:unit_recurring) do |t|
    t.pattern = 'recurring_billing/test/unit/**/*_test.rb'
    t.ruby_opts << '-rubygems'
    t.verbose = true
  end

  Rake::TestTask.new(:unit_tracker) do |t|
    t.pattern = 'tracker/test/unit/**/*_test.rb'
    t.ruby_opts << '-rubygems'
    t.verbose = true
  end

  Rake::TestTask.new(:unit_subscription) do |t|
    t.pattern = 'subscription_management/test/unit/**/*_test.rb'
    t.ruby_opts << '-rubygems'
    t.verbose = true
  end

  Rake::TestTask.new(:remote_recurring) do |t|
    t.pattern = 'recurring_billing/test/remote/**/*_test.rb'
    t.ruby_opts << '-rubygems'
    t.verbose = true
  end

  Rake::TestTask.new(:remote_tracker) do |t|
    t.pattern = 'tracker/test/remote/**/*_test.rb'
    t.ruby_opts << '-rubygems'
    t.verbose = true
  end

  Rake::TestTask.new(:remote_subscription) do |t|
    t.pattern = 'subscription_management/test/remote/**/*_test.rb'
    t.ruby_opts << '-rubygems'
    t.verbose = true
  end

  desc "Run all unit tests"
  task :unit => [:unit_recurring, :unit_tracker, :unit_subscription]

  desc "Run all remote tests"
  task :remote => [:remote_recurring, :remote_tracker, :remote_subscription]

  desc "Run both unit and remote tests"
  task :all => [:unit, :remote]

  task :default => 'unit'
end
