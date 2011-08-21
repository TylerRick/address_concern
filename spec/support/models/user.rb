class User < ActiveRecord::Base
  has_addresses :types => [:physical, :shipping, :billing]
end
