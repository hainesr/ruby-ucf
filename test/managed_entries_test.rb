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

require_relative 'test_helper'
require 'tmpdir'
require 'ucf'

# Classes to test managed entries.
class ManagedUCF < UCF::File

  private_class_method :new

  def initialize(filename)
    super(filename)
    register_managed_entry(ZipContainer::ManagedDirectory.new('src',
      :required => true))
    register_managed_entry(ZipContainer::ManagedDirectory.new('test'))
    register_managed_entry(ZipContainer::ManagedDirectory.new('lib'))
    register_managed_entry(ZipContainer::ManagedFile.new('index.html',
      :required => true))
  end

end

class ExampleUCF < UCF::File

  private_class_method :new

  def initialize(filename)
    super(filename)
    register_managed_entry(ZipContainer::ManagedDirectory.new('dir',
      :required => true))
    register_managed_entry(ZipContainer::ManagedFile.new('greeting.txt',
      :required => true))
  end

end

class ExampleUCF2 < UCF::File

  private_class_method :new

  def initialize(filename)
    super(filename)

    valid = Proc.new { |contents| contents.match(/[Hh]ello/) }
    register_managed_entry(ZipContainer::ManagedFile.new('greeting.txt',
       :required => true, :validation_proc => valid))
  end

end

class ExampleUCFDir < UCF::Dir

  private_class_method :new

  def initialize(filename)
    super(filename)

    valid = Proc.new { |contents| contents.match(/[Hh]ello/) }

    register_managed_entry(ZipContainer::ManagedFile.new('greeting.txt',
       :required => true, :validation_proc => valid))
  end

end

class TestManagedEntries < Minitest::Test

  # Check that the example UCF document does not validate as a ManagedUCF.
  def test_fail_verification
    refute(ManagedUCF.verify?(UCF_EXAMPLE))

    assert_raises(ZipContainer::MalformedContainerError) do
      ManagedUCF.verify!(UCF_EXAMPLE)
    end
  end

  # Check that the example UCF document does validate as an ExampleUCF.
  def test_pass_verification
    assert(ExampleUCF.verify?(UCF_EXAMPLE))

    ExampleUCF.verify!(UCF_EXAMPLE)
  end

  # Check that the example UCF document does validate as an ExampleUCF2.
  def test_pass_verification_2
    assert(ExampleUCF2.verify?(UCF_EXAMPLE))

    ExampleUCF2.verify!(UCF_EXAMPLE)
  end

  # Check that the example UCF directory validates.
  def test_pass_verification_dir
    assert(ExampleUCFDir.verify?(DIR_MNGD))

    ExampleUCFDir.verify!(DIR_MNGD)
  end

  # Check that a standard UCF Container can be created and things within it
  # are verified correctly.
  def test_create_standard_container
    Dir.mktmpdir do |dir|
      filename = File.join(dir, 'test.ucf')

      UCF::File.create(filename) do |c|
        c.mkdir('META-INF')
        assert(c.file.exists?('META-INF'))

        %w(container.xml manifest.xml).each do |file|
          full_path = "META-INF/#{file}"
          c.add(full_path, File.join(META_INF_DIR, file))
          assert(c.file.exists?(full_path))
        end
      end

      UCF::File.verify!(filename)
    end
  end

  # Check that a ManagedUCF does not verify immediately after creation.
  def test_create_bad_subclassed_container
    Dir.mktmpdir do |dir|
      filename = File.join(dir, 'test.ucf')

      ManagedUCF.create(filename) do |c|
        assert_raises(ZipContainer::MalformedContainerError) do
          c.verify!
        end
      end

      refute(ManagedUCF.verify?(filename))
      assert_raises(ZipContainer::MalformedContainerError) do
        ManagedUCF.verify!(filename)
      end
    end
  end

  # Check that a ManagedUCF does verify when required objects are added.
  def test_create_subclassed_container
    Dir.mktmpdir do |dir|
      filename = File.join(dir, 'test.ucf')

      ManagedUCF.create(filename) do |c|
        c.dir.mkdir('src')
        c.file.open('index.html', 'w') do |f|
          f.puts '<html />'
        end
      end

      assert(ManagedUCF.verify?(filename))
      ManagedUCF.verify!(filename)
    end
  end

  # Check that a ExampleUCF2 will only verify when required objects are added
  # with the correct contents.
  def test_create_subclassed_container_with_content_verification
    Dir.mktmpdir do |dir|
      filename = File.join(dir, 'test.ucf')

      ExampleUCF2.create(filename) do |c|
        assert_raises(ZipContainer::MalformedContainerError) do
          c.verify!
        end

        c.file.open('greeting.txt', 'w') do |f|
          f.puts 'Goodbye!'
        end

        assert_raises(ZipContainer::MalformedContainerError) do
          c.verify!
        end

        c.file.open('greeting.txt', 'w') do |f|
          f.puts "Hello, Y'All!"
        end

        c.verify!
      end

      assert(ExampleUCF2.verify?(filename))
      ExampleUCF2.verify!(filename)
    end
  end

end
