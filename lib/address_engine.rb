require "address_engine/version"
require 'rails'
require 'carmen'
require 'active_record'
require 'active_record_ignored_attributes'
require 'address_engine/attribute_normalizer'

module AddressEngine
  class Engine < Rails::Engine
  end
end
