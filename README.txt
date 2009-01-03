ServiceMerchant
===============

*Ruby toolkit for recurring billing and subscription management*

ServiceMerchant is an open source library for Software-as-a-Service
applications, based on subscription payments and various service
plans.  The library consists of number of well-isolated and
well-defined components, so that you may re-use portions of the
library, should you find the full functionality not required for
you. If you choose to use the library as whole, it should cover most
of your payments requirements, thus being billing module for your
application.

ServiceMerchant's main purpose is providing gateway-independent
support for recurring billing operations and powerful high-level tools
for building subscription-based billing atop of it.  It is built on
top of well-known [Active Merchant](http://www.activemerchant.org/)
library.

ServiceMerchant can be used both as a Rails plug-in or standalone Ruby
library.  It is also possible to integrate ServiceMerchant with
non-Ruby web applications via REST interface or common GUI.

== Supported Gateways

Currently [Authorize.Net](http://www.authorize.net/) and
[Paypal Website Payments Pro (US)](https://www.paypal.com/cgi-bin/webscr?cmd=_wp-pro-overview-outside)
are supported.

Generally, if Active Merchant supports some gateway with recurring
billing features then it is easy to add ServiceMerhant support as
well.  In this case you'll only need to add a few lines of proxy code
between Active Merchant and commont recurring billing API.

== Components

ServiceMerchant consists of three relatively independent components:

=== Recurring Billing API

Recurring Billing API is aimed at providing uniform interface for
recurring billing features of payment gateways and making switching
from one to another as painless as possible.

=== Transaction Tracker

Transactions Tracker stores local and readily available snapshots of
so-called "recurring billing profiles".  With Tracker you can check
account status much faster than vie gateway query (which not every
gateway API includes).  Transaction Tracker hooks automatically to
Recurring Billing API and updates your local copy of data according to
all ongoing operations.

=== Subscription Manager

Subscription Manager provides high-level logic for managing
subscription services, tariff plans, payment poliies and so on.  You
can even use it to automatically adjust final price with the tax of
appropriate region!

== Download

Currently this library is available from https://github.com/itteco/service_merchant

    git clone git://github.com/itteco/service_merchant.git

== Installation

0. Install Ruby, Rails and dependencies:

   In *nix software installation may require root privileges. Use "su"
   or "sudo" in case of lack rights.

   1) Install Ruby and Rails:

      please, refer to section #1 and #2 at
      http://wiki.rubyonrails.com/rails/pages/GettingStartedWithRails

   2) Install prerequisites:

      gem install activemerchant -v '1.3.2' --include-dependencies

      Test suite prerequisites:

      gem install mocha --include-dependencies
      gem install rake

      You may also need to update rubygems package manager if your
      version is too old

      gem install rubygems-update

   3) Install SQLite3 library:

      1. Install SQLite3:

         In *nix try your package manager.  You'll also need header
         files.  On Ubuntu packages names are sqlite3 and sqlite3-dev
         for library and header files respectively.

         Under Windows install it manually:

         a) download sqlitedll-*.zip from http://sqlite.org (for
         example, http://sqlite.org/sqlitedll-3_6_3.zip)

         b) extract sqlite3.dll somewhere within PATH
         (e.g. c:\ruby\bin, c:\windows\system32)

      2. Install Ruby wrapper:

         gem install sqlite3-ruby --include-dependencies
         (under Windows select <mswin32> option)

         In case of problems under Windows try to use older version:

         gem install --version 1.2.3 sqlite3-ruby

   4) [optional] Install HTMLDOC library:

      To use invoice generation feature in sample Rails application

      1. Install HTMLDOC:

         In *nix try your package manager. Package name is *htmldoc*.

         Under Windows download it from
         http://www.easysw.com/htmldoc/software.php and install it
         manually.

      2. Intall Ruby wrapper:

         gem install htmldoc


1.1. GEM installation:

  1) gem install servicemerchant

  #TODO#

1.2. Rails plugin installation

  1) Install plugin

      script/plugin install git://github.com/itteco/service_merchant.git

  2) [optional] Create ServiceMerchant database (will delete current
  database):

     rake service_merchant:create_all_tables

1.3. Manual installation:

  1) Download and unpack source

  2) [optional] Create ServiceMerchant database (will delete current
  database):

     cd {unpack_dir}
     rake create_all_tables

2. Configuration:

  The distribution contains sample config for test usage.  See
  tracker/test/fixtures.yml for details.  To run remote tests create

  !!! WARNING !!!

  Always use TEST accounts and TEST mode for your payment gateway
  until you've verified everything works correctly.


3. Test suite

Run unit tests:
    rake test:unit

Run remote tests (requires test accounts on gateways, see tracker/test/fixtures.yml):
    rake test:remote

Other test-related tasks:
    rake -T test

== Sample Usage

 1) Simple command-line sample app:

    cd {unpack_dir}
    ./demo.rb

    Please, refer to its source code for details.

 2) Simple web site (Ruby on Rails application):

    cd {unpack_dir}/sample_app
    rake sample_app:setup
    ./script/server

  and open http://127.0.0.1:3000/ and http://127.0.0.1:3000/admin in
  your browser. If both URLs does not work, try running

    ./script/server webrick
    (instead of ./script/server)

  Please, refer to its source code (for example, config/environment.rb
  and app/controllers/*) for details.

Both of these demo applications use sample configs to work.

== Known issues

1. No expection handling is provided for sample applications.

2. Not tested in LIVE payment gateway mode.

3. Database is stored inside module, single ServiceMerchant database
for all projects.

4. sqlite3-ruby 1.0.0 generates "Table not found" error on some Linux
machines.

== Roadmap

Add "sync payments status" feature - find out what accounts has
difficulties with payments - using

  1. Online sync - ask for account status directly from payment
  gateway

  2. Offline sync - import payment gateway report manualy

Pack source code as GEM and publish on rubyforge

== Developers

 - Alexander Lebedev <me@alexlebedev.com>
 - Artyom Scorecky <tonn81@gmail.com>
 - Anatoly Ivanov <mail@anatoly-ivanov.com>

Sponsored by [Itteco Software](http://itteco.com)

== Contributing

  #TODO#
