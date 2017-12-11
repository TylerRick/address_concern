require "address_engine/version"
require 'rails'
require 'carmen'
require 'active_record'
require 'active_record_ignored_attributes'
require 'address_engine/attribute_normalizer'

Carmen.i18n_backend.append_locale_path File.join(File.dirname(__FILE__), '../config/locale/overlay/en')

module AddressEngine
  class Engine < Rails::Engine
    initializer "add carmen locale" do
      # Wanted to put the append_locale_path here but it wasn't loading it for tests, so what do we
      # do?
    end
  end


  extend ActiveSupport::Concern
  module ClassMethods
    # Creates an +address+ association, representing the one and only address associated with the current record
    def has_address
      has_one :address, as: :addressable
    end

    # Creates an +addresses+ association, representing all addresses associated with the current record
    def has_addresses(options = {})
      has_many :addresses, as: :addressable
      (options[:types] || ()).each do |type|
        has_one :"#{type}_address", -> { where({address_type: type}) }, class_name: 'Address', as: :addressable
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include AddressEngine
end
