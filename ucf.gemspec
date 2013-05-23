# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "ucf"
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Robert Haines"]
  s.date = "2013-05-23"
  s.description = "A Ruby library for working with UCF files"
  s.email = ["rhaines@manchester.ac.uk"]
  s.extra_rdoc_files = [
    "Changes.rdoc",
    "Licence.rdoc",
    "ReadMe.rdoc"
  ]
  s.files = [
    "Changes.rdoc",
    "Licence.rdoc",
    "Rakefile",
    "ReadMe.rdoc",
    "examples/create_ucf.rb",
    "examples/verify_ucf.rb",
    "lib/ucf.rb",
    "lib/ucf/container.rb",
    "test/ts_ucf.rb",
    "ucf.gemspec",
    "version.yml"
  ]
  s.homepage = "http://www.taverna.org.uk/"
  s.rdoc_options = ["-N", "--tab-width=2", "--main=ReadMe.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.21"
  s.summary = "Universal Container Format Ruby Library"
  s.test_files = ["test/ts_ucf.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, ["~> 10.0.4"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.0.1"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.8.4"])
      s.add_runtime_dependency(%q<rubyzip>, ["~> 0.9.9"])
    else
      s.add_dependency(%q<rake>, ["~> 10.0.4"])
      s.add_dependency(%q<rdoc>, ["~> 4.0.1"])
      s.add_dependency(%q<jeweler>, ["~> 1.8.4"])
      s.add_dependency(%q<rubyzip>, ["~> 0.9.9"])
    end
  else
    s.add_dependency(%q<rake>, ["~> 10.0.4"])
    s.add_dependency(%q<rdoc>, ["~> 4.0.1"])
    s.add_dependency(%q<jeweler>, ["~> 1.8.4"])
    s.add_dependency(%q<rubyzip>, ["~> 0.9.9"])
  end
end

