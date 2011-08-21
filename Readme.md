Address Engine
==============

A reusable `Address` model for your Rails 3 apps.

Installation
============

Add `address_engine` to your `Gemfile`:

    gem 'address_engine'

Then run the generator to create your addresses table:

    rails generate address_engine:install
    rake db:migrate

You now have an `Address` model that you can use in your app just as if it were in your app/models directory.

Usage
=====

Because it depends on carmen, you have access to its country_select and state_select helpers.

You can either enter country name or code

Be aware that if the country you entered isn't recognized (in Carmen's database), it will be rejected and the country field reset to nil. This should probably be considered a bug and be fixed in a later release (using validations instead).

    Repurposed country column to be used for storing country *name* instead
    of code. Added country_code2 column to store ISO 3166-1 alpha-2 codes
    (and country_code3 for future expansion).
    
    Now you can set the country either by using the country= writer (if you
    want to use a country name as input) or the country_code= writer (if you
    want to use a country code as input). It will automatically update the
    other column for you and keep both of them up-to-date.
    
    Added some special handling of UK countries, since Carmen doesn't
    recognize 'England', etc. as countries but we want to allow those
    country names to be stored since they are kind of an important part of
    the address.
    
    Rewrote parts and readable_parts (renamed to lines) to make more concise
    and readable. Fixed problem with readable_parts where it added a comma
    before postal code.
    
You can compare Address objects using the same_as? method (provided by `active_record_ignored_attributes` gem).

Example:
...

Adding an `address` association to your ActiveRecord models
===========================================================

In any model that you wish to have an `address` or `addresses` association, just add a `has_address` or `has_addresses` line (respectively), like this:

    class Company < ActiveRecord::Base
      has_address
    end

    class User < ActiveRecord::Base
      has_addresses
    end

If you want to have several *individually accessible* addresses associated with a single model (such as a separate shipping and billing address), you can do something like this:

    class User < ActiveRecord::Base
      has_addresses :types => [:physical, :shipping, :billing]
    end

Then you can refer to them by name, like this:

    shipping_address = user.build_shipping_address(address: 'Some address')
    user.shipping_address # => shipping_address

Note that you aren't *limited* to only the address types you specifically list in your `has_addresses` declaration; you can still add and retrieve other addresses using the `has_many :addresses` association:

    vacation_address = user.addresses.build(address: 'Vacation', :address_type => 'Vacation')
    user.addresses # => [shipping_address, vacation_address]

Copyright
=========

Copyright (c) 2011 Paul Campbell
Copyright (c) 2011 Tyler Rick

See LICENSE.txt for further details.

