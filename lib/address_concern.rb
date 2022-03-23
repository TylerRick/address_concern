require 'rails'
require 'carmen'
require 'active_record'
require 'active_record_ignored_attributes'

Carmen.i18n_backend.append_locale_path File.join(File.dirname(__FILE__), '../config/locale/overlay/en')

require 'address_concern/version'
require 'address_concern/attribute_normalizer'
require_relative 'address_concern/address'
require_relative 'address_concern/address_associations'
