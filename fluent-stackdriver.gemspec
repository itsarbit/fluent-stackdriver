# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "fluent-stackdriver"
  gem.version       = "0.1.0"
  gem.authors       = ["Arbit Chen"]
  gem.email         = ["is.arbitt@gmail.com"]
  gem.summary       = %q{A generic Fluentd output plugin to send logs to an StackDriver}
  gem.description   = gem.summary

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "yajl-ruby", "~> 1.0"
  gem.add_runtime_dependency "fluentd", "~> 0.10.0"
  gem.add_development_dependency "bundler"
  gem.add_development_dependency "rake"
end
