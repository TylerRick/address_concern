class AddressWithSeparateAddressColumns < ApplicationRecord
  self.table_name = 'address_with_separate_address_columns'

  acts_as_address
end
