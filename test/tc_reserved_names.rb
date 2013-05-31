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

require 'ucf'

# A class to test the overriding of reserved names.
class NewUCF < UCF::Container
  def reserved_files
    super + ["index.html"]
  end

  def reserved_directories
    super + ["src", "test", "lib"]
  end
end

class TestReservedNames < Test::Unit::TestCase

  # Check the reserved names stuff all works correctly, baring in mind that
  # such comparisons for UCF documents should be case sensitive.
  def test_reserved_names
    UCF::Container.open($ucf_example) do |ucf|
      assert_equal(1, ucf.reserved_files.length)
      assert_equal(["mimetype"], ucf.reserved_files)
      assert(ucf.reserved_entry?("mimetype"))
      assert(ucf.reserved_entry?("mimetype/"))
      assert(ucf.reserved_entry?("MimeType"))

      assert_equal(1, ucf.reserved_directories.length)
      assert_equal(["META-INF"], ucf.reserved_directories)
      assert(ucf.reserved_entry?("META-INF"))
      assert(ucf.reserved_entry?("META-INF/"))
      assert(ucf.reserved_entry?("MeTa-iNf"))
      assert(ucf.reserved_entry?("MeTa-iNf/"))

      assert_equal(2, ucf.reserved_names.length)
      assert_equal(["mimetype", "META-INF"], ucf.reserved_names)

      refute(ucf.reserved_entry?("This_should_fail"))
      refute(ucf.reserved_entry?("META_INF"))
      refute(ucf.reserved_entry?("META_INF/"))
    end
  end

  # Check that overriding the reserved names in a sub-class works correctly
  def test_subclass_reserved_names
    NewUCF.open($ucf_example) do |ucf|
      assert_equal(2, ucf.reserved_files.length)
      assert_equal(["mimetype", "index.html"], ucf.reserved_files)
      assert(ucf.reserved_entry?("mimetype"))
      assert(ucf.reserved_entry?("mimetype/"))
      assert(ucf.reserved_entry?("MimeType"))
      assert(ucf.reserved_entry?("index.html"))
      assert(ucf.reserved_entry?("Index.HTML"))

      assert_equal(4, ucf.reserved_directories.length)
      assert_equal(["META-INF", "src", "test", "lib"], ucf.reserved_directories)
      assert(ucf.reserved_entry?("META-INF"))
      assert(ucf.reserved_entry?("META-INF/"))
      assert(ucf.reserved_entry?("MeTa-iNf"))
      assert(ucf.reserved_entry?("src"))
      assert(ucf.reserved_entry?("SRC"))
      assert(ucf.reserved_entry?("test"))
      assert(ucf.reserved_entry?("lib"))
      assert(ucf.reserved_entry?("lIb/"))

      assert_equal(6, ucf.reserved_names.length)
      assert_equal(["mimetype", "index.html", "META-INF", "src", "test", "lib"],
        ucf.reserved_names)

      refute(ucf.reserved_entry?("This_should_fail"))
      refute(ucf.reserved_entry?("META_INF"))
      refute(ucf.reserved_entry?("META_INF/"))
      refute(ucf.reserved_entry?("index.htm"))
    end
  end

  # Check that nothing happens when trying to delete the mimetype file.
  def test_delete_mimetype
    UCF::Container.open($ucf_example) do |ucf|
      assert(ucf.file.exists?("mimetype"))
      assert_nil(ucf.remove("mimetype"))
      assert(ucf.file.exists?("mimetype"))
    end
  end

  # Check that nothing happens when trying to rename the mimetype file.
  def test_rename_mimetype
    UCF::Container.open($ucf_example) do |ucf|
      assert(ucf.file.exists?("mimetype"))
      assert_nil(ucf.rename("mimetype", "something-else"))
      assert(ucf.file.exists?("mimetype"))
      refute(ucf.file.exists?("something-else"))
    end
  end

  # Check that nothing happens when trying to replace the contents of the
  # mimetype file.
  def test_replace_mimetype
    UCF::Container.open($ucf_example) do |ucf|
      assert(ucf.file.exists?("mimetype"))
      assert_nil(ucf.replace("mimetype", $zip_empty))
      assert_equal("application/epub+zip", ucf.file.read("mimetype"))
    end
  end

  # Check that an exception is raised when trying to add file with a reserved
  # name.
  def test_add_reserved
    UCF::Container.open($ucf_empty) do |ucf|
      assert_raises(UCF::ReservedNameClashError) do
        ucf.add("META-INF", $zip_empty)
      end
    end
  end

  # Check that an exception is raised when trying to add file with a reserved
  # name to a subclassed container.
  def test_subclass_add_reserved
    NewUCF.open($ucf_empty) do |ucf|
      assert_raises(UCF::ReservedNameClashError) do
        ucf.add("META-INF", $zip_empty)
      end

      assert_raises(UCF::ReservedNameClashError) do
        ucf.add("index.html", $zip_empty)
      end

      assert_raises(UCF::ReservedNameClashError) do
        ucf.add("SRC", $zip_empty)
      end
    end
  end

  # Check that nothing happens when trying to delete the META-INF directory.
  def test_delete_metainf
    UCF::Container.open($ucf_example) do |ucf|
      assert_nil(ucf.remove("META-INF"))
    end
  end

  # Check that nothing happens when trying to rename the META-INF directory.
  def test_rename_metainf
    UCF::Container.open($ucf_example) do |ucf|
      assert_nil(ucf.rename("META-INF", "something-else"))
    end
  end

  # Check that an exception is raised when trying to create a directory with a
  # reserved name.
  def test_mkdir_reserved
    UCF::Container.open($ucf_empty) do |ucf|
      assert_raises(UCF::ReservedNameClashError) do
        ucf.mkdir("META-INF")
      end
    end
  end

  # Check that an exception is raised when trying to create a directory with a
  # reserved name in a subclassed container.
  def test_subclass_mkdir_reserved
    NewUCF.open($ucf_empty) do |ucf|
      assert_raises(UCF::ReservedNameClashError) do
        ucf.mkdir("META-INF")
      end

      assert_raises(UCF::ReservedNameClashError) do
        ucf.mkdir("index.html")
      end

      assert_raises(UCF::ReservedNameClashError) do
        ucf.mkdir("Lib")
      end
    end
  end

  # Check that a file cannot be renamed to one of the reserved names.
  def test_rename_to_reserved
    UCF::Container.open($ucf_example) do |ucf|
      assert_raises(UCF::ReservedNameClashError) do
        ucf.rename("dir/code.rb", "mimetype")
      end

      assert_raises(UCF::ReservedNameClashError) do
        ucf.rename("dir", "META-INF")
      end
    end
  end

  # Check that a file cannot be renamed to one of the reserved names in a
  # subclassed container.
  def test_subclass_rename_to_reserved
    NewUCF.open($ucf_example) do |ucf|
      assert_raises(UCF::ReservedNameClashError) do
        ucf.rename("dir/code.rb", "mimetype")
      end

      assert_raises(UCF::ReservedNameClashError) do
        ucf.rename("dir", "META-INF")
      end

      assert_raises(UCF::ReservedNameClashError) do
        ucf.rename("dir/code.rb", "index.html")
      end

      assert_raises(UCF::ReservedNameClashError) do
        ucf.rename("dir", "Test")
      end
    end
  end

  # Check that the ruby-like File and Dir classes respect reserved names.
  def test_file_dir_ops_reserved
    UCF::Container.open($ucf_empty) do |ucf|
      assert_raises(UCF::ReservedNameClashError) do
        ucf.file.open("META-INF", "w") do |f|
          f.puts "TESTING"
        end
      end

      assert_nothing_raised(UCF::ReservedNameClashError) do
        ucf.file.open("mimetype") do |f|
          assert_equal("application/epub+zip", f.read)
        end
      end

      assert_nothing_raised(UCF::ReservedNameClashError) do
        ucf.file.delete("mimetype")
        assert(ucf.file.exists?("mimetype"))
      end

      assert_raises(UCF::ReservedNameClashError) do
        ucf.dir.mkdir("meta-inf")
      end
    end
  end

  # Check that the ruby-like File and Dir classes respect reserved names in a
  # subclassed container.
  def test_subclass_file_dir_ops_reserved
    NewUCF.open($ucf_empty) do |ucf|
      assert_raises(UCF::ReservedNameClashError) do
        ucf.file.open("META-INF", "w") do |f|
          f.puts "TESTING"
        end
      end

      assert_raises(UCF::ReservedNameClashError) do
        ucf.file.open("INDEX.HTML", "w") do |f|
          f.puts "TESTING"
        end
      end

      assert_nothing_raised(UCF::ReservedNameClashError) do
        ucf.file.open("mimetype") do |f|
          assert_equal("application/epub+zip", f.read)
        end
      end

      assert_nothing_raised(UCF::ReservedNameClashError) do
        ucf.file.delete("mimetype")
        assert(ucf.file.exists?("mimetype"))
      end

      assert_raises(UCF::ReservedNameClashError) do
        ucf.dir.mkdir("meta-inf")
      end

      assert_raises(UCF::ReservedNameClashError) do
        ucf.dir.mkdir("TEST")
      end

      assert_raises(UCF::ReservedNameClashError) do
        ucf.dir.mkdir("index.html")
      end
    end
  end

end
