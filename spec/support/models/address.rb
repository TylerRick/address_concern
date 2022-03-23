class Address < ApplicationRecord
  # include AddressConcern::Address
  acts_as_address
end
