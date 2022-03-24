class AddressWithCodeOnly < ApplicationRecord
  self.table_name = 'address_with_code_or_name_only'

  acts_as_address(
    state: {
      code_attribute: 'state',
    },
    country: {
      code_attribute: 'country'
    },
  )
end
