# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pkbot/version'

Gem::Specification.new do |spec|
  spec.name          = "pkbot"
  spec.version       = Pkbot::VERSION
  spec.authors       = ["pkbot"]
  spec.email         = ["pkbot@mail.com"]
  spec.description   = %q{Profkiosk bot}
  spec.summary       = %q{Profkiosk bot}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/) + ["lib/pkbot/config.yml"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
