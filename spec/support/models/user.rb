class User < ApplicationRecord
  # Could also do:
  #   has_addresses [:physical, :shipping, :billing]
  has_addresses
  has_address :physical
  has_address :shipping
  has_address :billing
end
