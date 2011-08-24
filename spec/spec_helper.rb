require 'bundler'
require 'bundler/setup'
Bundler.require(:default, :development)

#---------------------------------------------------------------------------------------------------

__DIR__ = Pathname.new(__FILE__).dirname
$LOAD_PATH.unshift __DIR__
$LOAD_PATH.unshift __DIR__ + '../lib'

#---------------------------------------------------------------------------------------------------
# ActiveRecord

require 'active_record'

log_file_path = __DIR__ + 'test.log'
log_file_path.truncate(0) rescue nil
ActiveRecord::Base.logger = Logger.new(log_file_path)

driver = (ENV["DB"] or "sqlite3").downcase
database_config = YAML::load(File.open(__DIR__ + "support/database.#{driver}.yml"))
ActiveRecord::Base.establish_connection(database_config)

require __DIR__ + 'support/schema'
require 'generators/address_engine/templates/migration'
CreateAddresses.up

#---------------------------------------------------------------------------------------------------
# RSpec

require 'rspec'

require 'active_record_ignored_attributes/matchers'


RSpec.configure do |config|
  config.include AttributeNormalizer::RSpecMatcher #, :type => :models
end

require 'address_engine'
require __DIR__ + '../app/models/address'

# Requires supporting ruby files in spec/support/
Dir[__DIR__ + 'support/**/*.rb'].each do |f|
  require f
end
