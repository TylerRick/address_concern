require 'rails'
require 'carmen'
require 'active_record'

Carmen.i18n_backend.append_locale_path File.join(File.dirname(__FILE__), '../config/locale/overlay/en')

require 'address_concern/version'
require 'address_concern/attribute_normalizer'
require 'address_concern/engine'

require_relative '../app/models/concerns/address'
require_relative '../app/models/concerns/address_associations'
