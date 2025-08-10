# Universal Container Format (UCF) Ruby Library
## Robert Haines

A Ruby library for creating, editing and validating UCF files.

[![Gem Version](https://badge.fury.io/rb/ucf.svg)](https://badge.fury.io/rb/ucf)
[![Tests](https://github.com/hainesr/ruby-ucf/actions/workflows/tests.yml/badge.svg)](https://github.com/hainesr/ruby-ucf/actions/workflows/tests.yml)
[![Linter](https://github.com/hainesr/ruby-ucf/actions/workflows/lint.yml/badge.svg)](https://github.com/hainesr/ruby-ucf/actions/workflows/lint.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)
[![Maintainability](https://api.codeclimate.com/v1/badges/feb6586086c0151adadd/maintainability)](https://codeclimate.com/github/hainesr/ruby-ucf/maintainability)
[![Coverage Status](https://coveralls.io/repos/github/hainesr/ruby-ucf/badge.svg)](https://coveralls.io/github/hainesr/ruby-ucf)

### Synopsis

This is a Ruby library for working with UCF documents. See [the specification](https://learn.adobe.com/wiki/display/PDFNAV/Universal+Container+Format) for more details. UCF is a type of EPUB and very similar to the [EPUB Open Container Format (OCF)](http://www.idpf.org/epub/30/spec/epub30-ocf.html).

Most of this library's API is provided by the underlying [zip-container gem](https://rubygems.org/gems/zip-container) so you will need to consult [that documentation as well](http://hainesr.github.io/ruby-zip-container/) in addition to this.

There are some examples of how to use the library provided in the examples directory. See the contents of the tests directory for even more.

### Usage

This library has two entry points.

The main `UCF::File` class is a specialization of [ZipContainer::File](https://hainesr.github.io/ruby-zip-container/latest/ZipContainer/File.html) which largely mimics the rubyzip [Zip::File](https://www.rubydoc.info/gems/rubyzip/3.0.1/Zip/File) and [Zip::FileSystem](http://www.rubydoc.info/gems/rubyzip/3.0.1/Zip/FileSystem) APIs.

The `UCF::Dir` class is a based upon the [ZipContainer::Dir](https://hainesr.github.io/ruby-zip-container/latest/ZipContainer/Dir.html) class which mimics, where possible, the core ruby [Dir API](https://rubyapi.org/3.0/o/dir).

There are some examples of how to use the library provided in the examples directory. See the contents of the tests directory for even more.

### Files in the META-INF directory

The UCF specification requires that files in the META-INF directory are validated against a schema if they are present. If the [nokogiri gem](https://rubygems.org/gems/nokogiri) is available then this library will use it to validate the contents of the `container.xml` and `manifest.xml` files. This functionality is not enforced on the user in case they are not using the META-INF directory and so would not need the extra dependency on nokogiri.

### What this library can not do yet

The basic requirements of a UCF document are all implemented but there are a number of optional features that are not yet provided.

* Validation of all file contents in the META-INF directory. The `container.xml` and `manifest.xml` files are validated but others are not yet.
* Digital signatures (this feature has been deferred until a future revision of the UCF specification. It will be supported by this gem when it is added to the specification).
* Encryption (this feature has been deferred until a future revision of the UCF specification. It will be supported by this gem when it is added to the  specification).

### Library versions

From version 1.0.0 onwards, the principles of [semantic versioning](https://semver.org/) are applied when numbering releases with new features or breaking changes.

### Developing Ruby UCF

Please see our [Code of Conduct](https://github.com/hainesr/ruby-ucf/blob/main/CODE_OF_CONDUCT.md) and our [contributor guidelines](https://github.com/hainesr/ruby-ucf/blob/main/CONTRIBUTING.md).

### Licence

BSD (See LICENCE file or http://www.opensource.org/licenses/bsd-license.php).
