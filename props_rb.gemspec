# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'props_rb/version'

Gem::Specification.new do |spec|
  spec.name          = "props_rb"
  spec.version       = PropsRb::VERSION
  spec.authors       = ["Shawn Anderson"]
  spec.email         = ["shawn42@gmail.com"]
  spec.summary       = %q{Ember.js style properties}
  spec.description   = %q{Ember.js style properties.}
  spec.homepage      = "https://github.com/shawn42/props_rb"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "active_support", "~> 4.1.6"
end
