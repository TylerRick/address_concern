# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "address_engine/version"

Gem::Specification.new do |s|
  s.name        = "address_engine"
  s.version     = AddressEngine::Version
  s.authors     = ["Paul Campbell", "Tyler Rick"]
  s.email       = ["paul@rslw.com", "github.com@tylerrick.com"]
  s.homepage    = %q{http://github.com/TylerRick/address_engine}
  s.summary     = %q{A reusable Address model for your Rails 3 apps}
  s.description = s.summary
  s.licenses = ["MIT"]

  s.add_dependency "rake"
  s.add_dependency "rspec"
  s.add_dependency "cucumber"
  s.add_dependency "rails", "~> 3.0"
  s.add_dependency "activerecord", "~> 3.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
