require 'rails'
require 'carmen'
require 'active_record'

Carmen.i18n_backend.append_locale_path File.join(File.dirname(__FILE__), '../config/locales/overlay/en')

require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
# Note: Because this gem has/is an engine, its "engine files" (under app) are autoload managed by
# the parent app. And you can't have more than one loader managing the same root. Therefore we can't
# do this:
#   loader.push_dir("#{__dir__}/../app/models")
# That is one reason, the models/concerns have been moved to lib, where it won't conflict with Rails
# app's loader.
loader.ignore("#{__dir__}/address_concern/attribute_normalizer.rb")
loader.ignore("#{__dir__}/address_concern/version.rb")
loader.ignore("#{__dir__}/core_extensions")
loader.ignore("#{__dir__}/generators")
loader.setup

require 'address_concern/version'
#pp loader.autoloads
loader.eager_load
#require_relative '../app/models/address_concern/address'

# When used in a Rails app, this isn't needed because the engine will add its locale load paths, but
# when not using Rails, including from our tests, the engine isn't loaded.
I18n.load_path.unshift(
  *Dir.glob(
    x=File.expand_path(
      File.join(%w[.. config locales *.yml]), File.dirname(__FILE__)
    )
  )
)
