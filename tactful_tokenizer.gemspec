# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "tactful_tokenizer/version"

Gem::Specification.new do |s|
  s.name        = "tactful_tokenizer"
  s.version     = TactfulTokenizer::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = [""]
  s.email       = [""]
  s.homepage    = ""
  s.summary     = %q{Summary}
  s.description = %q{Desc}

  s.rubyforge_project = "tactful_tokenizer"

  s.files         = `git ls-files`.split($\)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
end
