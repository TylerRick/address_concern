# Address Concern

A reusable polymorphic `Address` model concern for your Rails apps.

# Installation

Add `address_engine` to your `Gemfile`:

    gem 'address_engine'

Then run the generator to create your addresses table:

    rails generate address_engine:install
    rake db:migrate

You now have an `Address` model that you can use in your app just as if it were in your `app/models` directory.

# Usage

## Base usage

```ruby
class Address < ApplicationRecord
  include AddressConcern
end
```

## `belongs_to_address`

```ruby
class Person < ApplicationRecord
  belongs_to_address
end

person = Person.new
person.build_address(address: '...')
```

## Multiple addresses on same model

```ruby
class User < ApplicationRecord
  belongs_to_address :shipping_address
  belongs_to_address :billing_address
end

user = User.new
shipping_address = user.build_shipping_address(address: '...')
billing_address  = user.build_billing_address( address: '...')
```

See "Adding an `address` association to your ActiveRecord models" section for more examples of
configuration your associations.


# Adding an `address` association to your ActiveRecord models

You can add an address association (or multiple) to any model that has an address.

You can associate with the address via a `belongs_to`, `has_one`, or `has_many` — whichever makes
the most sense for your use case.

You can either use standard ActiveRecord association macros, like this:

```ruby
class Person < ApplicationRecord
  belongs_to :address
end
```

... or use the provided macros:

## `belongs_to_address`

```ruby
class Person < ApplicationRecord
  belongs_to_address
end

person = Person.new
person.build_address(address: '...')
```

If needed, you can pass a name as well as options for the `belongs_to` and (optional) inverse `has_one`
associations.

```ruby
class Child < ApplicationRecord
  belongs_to_address inverse: false
  belongs_to_address :secret_hideout, inverse: {name: :child_for_secret_hideout}
end

child = Child.new
child.build_secret_hideout(address: '...')
```

## `has_address`

`has_address` creates a `has_one :address` association:

```ruby
class Company < ApplicationRecord
  has_address
end
```

```
company = company.new
address = company.build_address(address: '...')
```

This also adds a polymorphic `addressable` association on the Address model (not available if you're
using `belongs_to :address` on your addressable models):

```ruby
belongs_to :addressable, :polymorphic => true
```

## `has_addresses`

`has_addresses` creates a `has_many :addresses` association:

```ruby
class User < ApplicationRecord
  has_addresses
end
```

If you want to have several *individually accessible* addresses associated with a single model (such
as a separate shipping and billing address), you can do something like this:

```ruby
class User < ApplicationRecord
  has_addresses :types => [:physical, :shipping, :billing]
end
```

Then you can refer to them by name, like this:

```ruby
shipping_address = user.build_shipping_address(address: 'Some address')
user.shipping_address # => shipping_address
```

Note that you aren't *limited* to only the address types you specifically list in your
`has_addresses` declaration; you can still add and retrieve other addresses using the `has_many
:addresses` association:

```ruby
vacation_address = user.addresses.build(address: 'Vacation', :address_type => 'Vacation')
user.addresses # => [shipping_address, vacation_address]
```

# Country/state database

Country/state data comes from the [`carmen`](https://github.com/carmen-ruby/carmen) gem.

- You can set the country either by using the `country=` writer (if you want to use a country name
  as input in your frontend) or the `country_code=` writer (if you want to use a country code as
  input). It will automatically update the other column for you and keep both of them up-to-date.
- The country name is stored in the `country` attribute (most common use case).
- Country codes can be optionally get/set via the `country_code2` (ISO 3166-1 alpha-2 codes)
  (aliased as `country_code`) or `country_code3` attributes.
- Be aware that if the country you entered isn't recognized (in Carmen's database), it will be
  rejected and the country field reset to nil. This should probably be considered a bug and be fixed
  in a later release (using validations instead).

Other notes regarding country:

- Added some special handling of UK countries, since Carmen doesn't recognize 'England', etc. as
  countries but we want to allow those country names to be stored since they may be a part of the
  address you want to preserve.

# View helpers

Because this gem depends on [`carmen`](https://github.com/carmen-ruby/carmen), you have access to
its `country_select` and `state_select` helpers.

# Related Projects

(Along with some feature/API ideas that we may want to incorporate (pull requests welcome!).)

- https://github.com/ankane/mainstreet — A standard US address model for Rails
  - Use `alias_attribute` to map existing field names
  - Add new fields like `original_attributes` and `verification_info`
  - Uses `SmartyStreets` to verify addresses (`valid?` returns false).
  - [`acts_as_address` association macro](https://github.com/ankane/mainstreet/blob/master/lib/mainstreet.rb)
  - [`Address` model generator](https://github.com/ankane/mainstreet/blob/master/lib/generators/mainstreet/address_generator.rb)
  - `acts_as_address` could potentially be included into our `Address` model and both gems used together

- https://github.com/yrgoldteeth/whereabouts — A simple rails plugin that adds a polymorphic address model
  - `has_whereabouts :location, {:geocode => true}`
  - `has_whereabouts :location, {:validate => [:city, :state, :zip]}`
  - [`has_whereabouts` association macro](https://github.com/yrgoldteeth/whereabouts/blob/master/lib/whereabouts_methods.rb)
  - [`Address` model generator](https://github.com/yrgoldteeth/whereabouts/blob/master/lib/generators/address/templates/address.rb)

- https://github.com/wilbert/addresses — An Address engine to use Country, State, City and Neighborhood models
  - Allows you use these models: `Country`, `State` (belongs to country), `City` (belongs to State), `Neighborhood` (belongs to city), `Address` (Belongs to `Neighborhood` and `City`, because neighborhood is not required)
  - `address.city = Address::City.find(city_id)`
  - `mount Addresses::Engine => "/addresses"`
  - [`Address` model](https://github.com/wilbert/addresses/blob/master/app/models/addresses/address.rb)

- https://github.com/huerlisi/has_vcards — Rails plugin providing VCard like contact and address models and helpers
  - [`Address` model](https://github.com/huerlisi/has_vcards/blob/master/app/models/has_vcards/address.rb)

Not maintained for 3+ years:
- https://github.com/mobilityhouse/acts_as_addressable — Make your models addressable
  - `acts_as_addressable :postal, :billing`
  - [`acts_as_addressable` association macro](https://github.com/mobilityhouse/acts_as_addressable/blob/master/lib/acts_as_addressable/addressable.rb)
  - [`Address` model generator](https://github.com/mobilityhouse/acts_as_addressable/blob/master/lib/generators/acts_as_addressable/templates/address.rb)
- https://github.com/mariusz360/postally_addressable — Add postal addresses to your models
  - [`has_postal_address` association macro](https://github.com/mariusz360/postally_addressable/blob/master/lib/postally_addressable/has_postal_address.rb)
  - [`PostalAddress` model](https://github.com/mariusz360/postally_addressable/blob/master/app/models/postal_address.rb)
    - `alias_attribute :state, :province`
- https://github.com/nybblr/somewhere — Serialized address class for use with Rails models. Like it should be.
  - `address :billing, :postal_code => :zip, :include_prefix => false`
  - `address.to_hash :exclude => [:country]`
  - `address.to_s :country => false`
  - [`Address` model](https://github.com/nybblr/somewhere/blob/master/lib/address.rb)
  - [`address` association macro](https://github.com/nybblr/somewhere/blob/master/lib/somewhere.rb)
- https://github.com/rumblelabs/is_addressable

# License

Licensed under the MIT License.

See LICENSE.txt for further details.

