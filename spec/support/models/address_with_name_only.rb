class AddressWithNameOnly < ApplicationRecord
  self.table_name = 'address_with_code_or_name_only'

  acts_as_address
end
