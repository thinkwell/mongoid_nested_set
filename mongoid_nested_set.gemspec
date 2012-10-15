# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mongoid_nested_set/version"

Gem::Specification.new do |s|
  s.name        = "mongoid_nested_set"
  s.version     = MongoidNestedSet::VERSION
  s.authors     = ["Brandon Turner"]
  s.email       = ["bt@brandonturner.net"]
  s.homepage    = "http://github.com/thinkwell/mongoid_nested_set"
  s.summary     = %q{Nested set based tree implementation for Mongoid}
  s.description = %q{Fully featured tree implementation for Mongoid using the nested set model}
  s.licenses    = ["MIT"]

  s.rubyforge_project = "mongoid_nested_set"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specifiy any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency(%q<mongoid>, [">= 3.0.0"])

  s.add_development_dependency(%q<rspec>, [">= 2.7.0"])
  s.add_development_dependency(%q<bundler>, [">= 1.0.21"])
  s.add_development_dependency(%q<simplecov>)
  s.add_development_dependency(%q<simplecov-rcov>)
end

