require 'bundler/gem_tasks'

#---------------------------------------------------------------------------------------------------
require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

desc "Start a console with this version of library loaded"
task :console do
  require 'bundler/setup'
  require 'address_concern'
  require 'irb'
  ARGV.clear
  IRB.start
end

task :default => :spec
