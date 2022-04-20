# This file is based on effective_addresses/lib/effective_addresses/engine.rb

module AddressConcern
  class Engine < ::Rails::Engine
    engine_name 'address_concern'

    initializer 'address_concern.active_record' do |app|
      ActiveSupport.on_load :active_record do
        #
      end
    end

    # Set up our default configuration options.
    #initializer 'address_concern.defaults', before: :load_config_initializers do |app|
    #  eval File.read("#{config.root}/config/address_concern.rb")
    #end
  end
end
