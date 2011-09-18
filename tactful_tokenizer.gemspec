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

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
