class Address < ApplicationRecord
  #normalize_attributes :name
  acts_as_address
end
