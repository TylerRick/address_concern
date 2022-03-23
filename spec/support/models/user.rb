class User < ApplicationRecord
  has_addresses :types => [:physical, :shipping, :billing]
end
