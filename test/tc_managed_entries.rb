# Copyright (c) 2013 The University of Manchester, UK.
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

require 'tmpdir'
require 'ucf'

# Classes to test managed entries.
class ManagedUCF < UCF::Container

  private_class_method :new

  def initialize(filename)
    super(filename)
    register_managed_entry(UCF::ManagedDirectory.new("src", true))
    register_managed_entry(UCF::ManagedDirectory.new("test"))
    register_managed_entry(UCF::ManagedDirectory.new("lib"))
    register_managed_entry(UCF::ManagedFile.new("index.html", true))
  end

end

class ExampleUCF < UCF::Container

  private_class_method :new

  def initialize(filename)
    super(filename)
    register_managed_entry(UCF::ManagedDirectory.new("dir", true))
    register_managed_entry(UCF::ManagedFile.new("greeting.txt", true))
  end

end

class ExampleUCF2 < UCF::Container

  private_class_method :new

  def initialize(filename)
    super(filename)

    valid = Proc.new { |contents| contents.match(/[Hh]ello/) }
    register_managed_entry(UCF::ManagedFile.new("greeting.txt", true, valid))
  end

end

class TestManagedEntries < Test::Unit::TestCase

  # Check that the example UCF document does not validate as a ManagedUCF.
  def test_fail_verification
    refute(ManagedUCF.verify($ucf_example))

    assert_raises(UCF::MalformedUCFError) do
      ManagedUCF.verify!($ucf_example)
    end
  end

  # Check that the example UCF document does validate as an ExampleUCF.
  def test_pass_verification
    assert(ExampleUCF.verify($ucf_example))

    assert_nothing_raised(UCF::MalformedUCFError) do
      ExampleUCF.verify!($ucf_example)
    end
  end

  # Check that the example UCF document does validate as an ExampleUCF2.
  def test_pass_verification_2
    assert(ExampleUCF2.verify($ucf_example))

    assert_nothing_raised(UCF::MalformedUCFError) do
      ExampleUCF2.verify!($ucf_example)
    end
  end

  # Check that a standard Container can be created
  def test_create_standard_container
    Dir.mktmpdir do |dir|
      filename = File.join(dir, "test.ucf")

      assert_nothing_raised do
        UCF::Container.create(filename) do |c|
          c.mkdir("META-INF")
          assert(c.file.exists?("META-INF"))

          c.file.open("META-INF/container.xml", "w") do |f|
            f.puts "<?xml version=\"1.0\"?>"
          end
          assert(c.file.exists?("META-INF/container.xml"))
        end
      end

      assert_nothing_raised(UCF::MalformedUCFError) do
        UCF::Container.verify!(filename)
      end
    end
  end

  # Check that a ManagedUCF does not verify immediately after creation.
  def test_create_bad_subclassed_container
    Dir.mktmpdir do |dir|
      filename = File.join(dir, "test.ucf")

      assert_nothing_raised do
        ManagedUCF.create(filename) do |c|
          assert_raises(UCF::MalformedUCFError) do
            c.verify!
          end
        end
      end

      refute(ManagedUCF.verify(filename))
      assert_raises(UCF::MalformedUCFError) do
        ManagedUCF.verify!(filename)
      end
    end
  end

  # Check that a ManagedUCF does verify when required objects are added.
  def test_create_subclassed_container
    Dir.mktmpdir do |dir|
      filename = File.join(dir, "test.ucf")

      assert_nothing_raised do
        ManagedUCF.create(filename) do |c|
          c.dir.mkdir("src")
          c.file.open("index.html", "w") do |f|
            f.puts "<html />"
          end
        end
      end

      assert(ManagedUCF.verify(filename))
      assert_nothing_raised(UCF::MalformedUCFError) do
        ManagedUCF.verify!(filename)
      end
    end
  end

  # Check that a ExampleUCF2 will only verify when required objects are added
  # with the correct contents.
  def test_create_subclassed_container_with_content_verification
    Dir.mktmpdir do |dir|
      filename = File.join(dir, "test.ucf")

      assert_nothing_raised do
        ExampleUCF2.create(filename) do |c|
          assert_raises(UCF::MalformedUCFError) do
            c.verify!
          end

          c.file.open("greeting.txt", "w") do |f|
            f.puts "Goodbye!"
          end

          assert_raises(UCF::MalformedUCFError) do
            c.verify!
          end

          c.file.open("greeting.txt", "w") do |f|
            f.puts "Hello, Y'All!"
          end

          assert_nothing_raised(UCF::MalformedUCFError) do
            c.verify!
          end
        end
      end

      assert(ExampleUCF2.verify(filename))
      assert_nothing_raised(UCF::MalformedUCFError) do
        ExampleUCF2.verify!(filename)
      end
    end
  end

end
