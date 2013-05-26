# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "noid/version"

Gem::Specification.new do |s|
  s.name        = "noid"
  s.version     = Noid::VERSION
  s.authors     = ["Chris Beer"]
  s.email       = ["chris@cbeer.info"]
  s.homepage    = "http://github.com/microservices/noid"
  s.summary     = %q{Nice Opaque Identifier}
  s.description = %q{}

  s.rubyforge_project = "noid"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", ">= 2.0"
end
