# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'db_mailer/version'

Gem::Specification.new do |spec|
  spec.name          = "db_mailer"
  spec.version       = DbMailer::VERSION
  spec.authors       = ["Radek Paviensky"]
  spec.email         = ["radek@paviensky.com"]
  spec.summary       = %q{Database mail delivery method}
  spec.description   = %q{Delivers e-mail by writing them into the database.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 3.2.0"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
