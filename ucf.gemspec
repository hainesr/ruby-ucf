# Copyright (c) 2013-2023 The University of Manchester, UK.
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
#  * Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
#  * Neither the names of The University of Manchester nor the names of its
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# Author: Robert Haines

require_relative 'lib/ucf/version'

Gem::Specification.new do |s|
  s.name        = 'ucf'
  s.version     = UCF::VERSION
  s.authors     = ['Robert Haines', 'Finn Bacall']
  s.email       = ['robert.haines@manchester.ac.uk']
  s.homepage    = 'https://github.com/hainesr/ruby-ucf'
  s.platform    = Gem::Platform::RUBY
  s.summary     = 'Universal Container Format (UCF) Ruby Library'
  s.description =
    'A Ruby library for working with Universal Container ' \
    'Format files - a type of EPUB document. See the UCF specification ' \
    '(https://learn.adobe.com/wiki/display/PDFNAV/Universal+Container+Format) ' \
    'for details. They are very similar, although not as restrictive, as ' \
    'the EPUB Open Container Format (OCF) ' \
    '(http://www.idpf.org/epub/30/spec/epub30-ocf.html).'

  s.license       = 'BSD'
  s.require_paths = ['lib']
  s.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/hainesr/ruby-ucf/issues',
    'changelog_uri' => "https://github.com/hainesr/ruby-ucf/blob/v#{s.version}/Changelog.md",
    'documentation_uri' => 'https://hainesr.github.io/ruby-ucf',
    'source_code_uri' => "https://github.com/hainesr/ruby-ucf/tree/v#{s.version}",
    'rubygems_mfa_required' => 'true'
  }

  s.required_ruby_version = '>= 2.6'

  s.add_development_dependency 'minitest', '~> 5.16.0'
  s.add_development_dependency 'nokogiri', '~> 1.13.0'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rdoc', '~> 6.4.0'
  s.add_development_dependency 'rubocop', '~> 1.50.0'
  s.add_development_dependency 'rubocop-minitest', '~> 0.30.0'
  s.add_development_dependency 'rubocop-performance', '~> 1.17.0'
  s.add_development_dependency 'rubocop-rake', '~> 0.6.0'
  s.add_development_dependency 'simplecov', '0.18.3'
  s.add_development_dependency 'simplecov-lcov', '~> 0.8.0'

  s.add_runtime_dependency 'zip-container', '~> 4.0.1'
end
