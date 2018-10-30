class Child < ActiveRecord::Base
  belongs_to_address
  belongs_to_address :secret_hideout, inverse: {name: :child_for_secret_hideout}
end
