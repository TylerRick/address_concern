class AddressCustomAttrNames < ApplicationRecord
  self.table_name = 'addresses'

  acts_as_address(
    country: {
      name_attribute: 'country',
      code_attribute: 'country_code',
      carmen_code: 'code', # same as 'alpha_2_code'
    }
  )
end
