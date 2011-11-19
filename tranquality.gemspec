# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "tranquality/version"

Gem::Specification.new do |s|
  s.name        = "tranquality"
  s.version     = Tranquality::VERSION
  s.authors     = ["Burke Libbey"]
  s.email       = ["burke@burkelibbey.org"]
  s.homepage    = ""
  s.summary     = "Code quality tools"
  s.description = "Code quality tools"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'sexp_processor', '~> 3.0.8'
  s.add_runtime_dependency 'ruby_parser',    '~> 2.3.1'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'guard'
end
