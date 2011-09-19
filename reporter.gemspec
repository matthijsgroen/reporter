# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "reporter/version"

Gem::Specification.new do |s|
  s.name        = "reporter"
  s.version     = Reporter::VERSION
  s.authors     = ["Matthijs Groen"]
  s.email       = ["matthijs.groen@gmail.com"]
  s.homepage    = "https://github.com/matthijsgroen/reporter"
  s.summary     = %q{Report builder.}
  s.description = %q{Reporter adds a consistent way to build reports.}

  s.rubyforge_project = "reporter"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
