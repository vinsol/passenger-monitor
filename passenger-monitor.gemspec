# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'passenger_monitor/version'

Gem::Specification.new do |spec|
  spec.name          = "passenger_monitor"
  spec.version       = PassengerMonitor::VERSION
  spec.authors       = ["Akshay Vishnoi"]
  spec.email         = ["akshay.vishnoi@yahoo.com"]
  spec.summary       = %q{Monitors passenger workers and kill bloated ones}
  spec.description   = %q{Monitors passenger workers of your application and if
    the workers exceeds the memory limit then it kills it (first gracefully, wait and
    then forcefully).}
  spec.homepage      = "https://github.com/vinsol/passenger-monitor"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.4"
end
