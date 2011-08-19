require 'bundler'
require 'bundler/setup'
#Bundler.require(:default)
require 'carmen'

#---------------------------------------------------------------------------------------------------

__DIR__ = Pathname.new(__FILE__).dirname
$LOAD_PATH.unshift __DIR__
$LOAD_PATH.unshift __DIR__ + '../lib'

#---------------------------------------------------------------------------------------------------
# ActiveRecord

require 'active_record'
driver = (ENV["DB"] or "sqlite3").downcase
database_config = YAML::load(File.open(__DIR__ + "support/database.#{driver}.yml"))
ActiveRecord::Base.establish_connection(database_config)

#---------------------------------------------------------------------------------------------------
# RSpec

require 'rspec'

RSpec.configure do |config|
  #
end

require 'address_engine'
require __DIR__ + '../app/models/address'

# Requires supporting ruby files in spec/support/
Dir[__DIR__ + 'support/**/*.rb'].each do |f|
  require f
end
