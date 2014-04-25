# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "tactful_tokenizer/version"

Gem::Specification.new do |s|
  s.name        = "tactful_tokenizer"
  s.version     = TactfulTokenizer::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matthew Bunday", "Sergey Kishenin"]
  s.email       = ["mkbunday@gmail.com"]
  s.homepage    = "http://github.com/zencephalon/Tactful_Tokenizer"
  s.summary     = "High accuracy sentence tokenization for Ruby."
  s.description = "TactfulTokenizer uses a naive bayesian model train on the Brown and WSJ corpuses to provide high quality sentence tokenization."
  s.license     = "GPL-3"

  s.rubyforge_project = "tactful_tokenizer"

  s.files         = `git ls-files`.split($\)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", "~> 0"
  s.add_development_dependency "rake", "~> 0"
end
