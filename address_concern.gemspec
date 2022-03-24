# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "address_concern/version"

Gem::Specification.new do |s|
  s.name        = "address_concern"
  s.version     = AddressConcern.version
  s.authors     = ["Paul Campbell", "Tyler Rick"]
  s.email       = ["paul@rslw.com", "tyler@tylerrick.com"]
  s.homepage    = %q{http://github.com/TylerRick/address_concern}
  s.summary     = %q{A reusable Address model for your Rails apps}
  s.description = s.summary
  s.licenses = ["MIT"]

  s.add_dependency "rake"
  s.add_dependency "rails", ">= 4.0"
  s.add_dependency "activerecord", ">= 4.0"
  s.add_dependency "activesupport", ">= 4.0"
  s.add_dependency "carmen", '>= 1.1.1'
  #s.add_dependency "attribute_normalizer"

  s.add_development_dependency 'active_record_ignored_attributes' # for be_same_as
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'sqlite3'
  #s.add_development_dependency 'mysql2', '~>0.2.11'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  #s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
