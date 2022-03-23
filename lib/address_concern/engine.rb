# This file is based on effective_addresses/lib/effective_addresses/engine.rb

module AddressConcern
  class Engine < ::Rails::Engine
    engine_name 'address_concern'

    config.autoload_paths   += Dir["#{config.root}/app/models/concerns"]
    config.eager_load_paths += Dir["#{config.root}/app/models/concerns"]

    initializer 'address_concern.active_record' do |app|
      ActiveSupport.on_load :active_record do
        AddressConcern::Address::Base
        AddressConcern::AddressAssociations
        # ActiveRecord::Base.extend(AddressConcern::Address::Base)
      end
    end

    # Set up our default configuration options.
    initializer 'address_concern.defaults', before: :load_config_initializers do |app|
      eval File.read("#{config.root}/config/address_concern.rb")
    end
  end
end
