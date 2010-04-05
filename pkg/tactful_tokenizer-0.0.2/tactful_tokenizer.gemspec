# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{tactful_tokenizer}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matthew Bunday"]
  s.cert_chain = ["/home/slyshy/.ssh/gem-public_cert.pem"]
  s.date = %q{2010-04-04}
  s.description = %q{A high accuracy naive bayesian sentence tokenizer based on Splitta.}
  s.email = %q{mkbunday @nospam@ gmail.com}
  s.extra_rdoc_files = ["README.rdoc", "lib/models/features.mar", "lib/models/lower_words.mar", "lib/models/non_abbrs.mar", "lib/tactful_tokenizer.rb", "lib/word_tokenizer.rb"]
  s.files = ["Manifest", "README.rdoc", "Rakefile", "lib/models/features.mar", "lib/models/lower_words.mar", "lib/models/non_abbrs.mar", "lib/tactful_tokenizer.rb", "lib/word_tokenizer.rb", "test/sample.txt", "test/test.rb", "test/test_out.txt", "test/verification_out.txt", "tactful_tokenizer.gemspec"]
  s.homepage = %q{http://github.com/SlyShy/Tactful_Tokenizer}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Tactful_tokenizer", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{tactful_tokenizer}
  s.rubygems_version = %q{1.3.6}
  s.signing_key = %q{/home/slyshy/.ssh/gem-private_key.pem}
  s.summary = %q{A high accuracy naive bayesian sentence tokenizer based on Splitta.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
