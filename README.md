# Address Engine #

An `Address` model for your Rails 3 apps.

# Installation #

Add `address_engine` to your `Gemfile`:

    gem 'address_engine'

then run the generator to create your addresses table:

    rails generate address_engine:install
    rake db:migrate

Your'e done! You now have an `Address` model with some sensible validations and fields that will go a long long way:

    create_table "addresses" do |t|
      t.references :addressable, :polymorphic => true
      t.string   "name"
      t.text     "address"
      t.string   "city"
      t.string   "province"
      t.string   "postal_code"
      t.string   "country"
      t.string   "email"
      t.string   "phone"
      t.timestamps
    end
    
Requires the `carmen` gem (https://rubygems.org/gems/carmen):

    gem install carmen

## Copyright ##

Copyright (c) 2011 Paul Campbell. See LICENSE.txt for
further details.

