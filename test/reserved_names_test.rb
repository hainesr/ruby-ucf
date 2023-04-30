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
require 'ucf'

# A class to test the overriding of reserved and managed names.
class NewUCF < UCF::File

  private_class_method :new

  def initialize(filename)
    super(filename)
    register_managed_entry(ZipContainer::ManagedDirectory.new('src'))
    register_managed_entry(ZipContainer::ManagedDirectory.new('test'))
    register_managed_entry(ZipContainer::ManagedDirectory.new('lib'))
    register_managed_entry(ZipContainer::ManagedFile.new('index.html'))

    register_reserved_name('reserved_dir')
  end

end

class TestReservedNames < Minitest::Test

  # Check that the reserved names verify correctly.
  def test_verify_reserved_name
    assert(NewUCF.verify?(UCF_EXAMPLE))

    NewUCF.verify!(UCF_EXAMPLE)
  end

  # Check the reserved names stuff all works correctly, baring in mind that
  # such comparisons for UCF documents should be case sensitive.
  def test_reserved_names
    UCF::File.open(UCF_EXAMPLE) do |ucf|
      assert_equal(1, ucf.reserved_names.length)
      assert_equal(['mimetype'], ucf.reserved_names)
      assert_equal(6, ucf.managed_files.length)
      assert_equal(['META-INF/container.xml',
        'META-INF/manifest.xml', 'META-INF/metadata.xml',
        'META-INF/signatures.xml', 'META-INF/encryption.xml',
        'META-INF/rights.xml'], ucf.managed_file_names)
      assert(ucf.reserved_entry?('mimetype'))
      assert(ucf.reserved_entry?('mimetype/'))
      assert(ucf.reserved_entry?('MimeType'))
      assert(ucf.managed_entry?('META-INF/container.xml'))
      assert(ucf.managed_entry?('META-INF/manifest.xml'))
      assert(ucf.managed_entry?('MeTa-INF/maniFest.XML'))

      assert_equal(1, ucf.managed_directories.length)
      assert_equal(['META-INF'], ucf.managed_directory_names)
      assert(ucf.managed_entry?('META-INF'))
      assert(ucf.managed_entry?('META-INF/'))
      assert(ucf.managed_entry?('MeTa-iNf'))
      assert(ucf.managed_entry?('MeTa-iNf/'))
      refute(ucf.reserved_entry?('META-INF'))

      assert_equal(7, ucf.managed_entries.length)
      assert_equal(['META-INF/container.xml',
        'META-INF/manifest.xml', 'META-INF/metadata.xml',
        'META-INF/signatures.xml', 'META-INF/encryption.xml',
        'META-INF/rights.xml', 'META-INF'], ucf.managed_entry_names)

      refute(ucf.managed_entry?('This_should_fail'))
      refute(ucf.managed_entry?('META_INF'))
      refute(ucf.managed_entry?('META_INF/'))
    end
  end

  # Check that overriding the reserved names in a sub-class works correctly
  def test_subclass_reserved_names
    NewUCF.open(UCF_EXAMPLE) do |ucf|
      assert_equal(2, ucf.reserved_names.length)
      assert_equal(['mimetype', 'reserved_dir'], ucf.reserved_names)
      assert_equal(7, ucf.managed_files.length)
      assert_equal(['index.html', 'META-INF/container.xml',
        'META-INF/manifest.xml', 'META-INF/metadata.xml',
        'META-INF/signatures.xml', 'META-INF/encryption.xml',
        'META-INF/rights.xml'], ucf.managed_file_names)
      assert(ucf.reserved_entry?('mimetype'))
      assert(ucf.reserved_entry?('mimetype/'))
      assert(ucf.reserved_entry?('MimeType'))
      assert(ucf.managed_entry?('index.html'))
      assert(ucf.managed_entry?('Index.HTML'))
      refute(ucf.reserved_entry?('index.html'))

      assert_equal(4, ucf.managed_directories.length)
      assert_equal(['META-INF', 'src', 'test', 'lib'],
        ucf.managed_directory_names)
      assert(ucf.managed_entry?('META-INF'))
      assert(ucf.managed_entry?('META-INF/'))
      assert(ucf.managed_entry?('MeTa-iNf'))
      assert(ucf.managed_entry?('src'))
      assert(ucf.managed_entry?('SRC'))
      assert(ucf.managed_entry?('test'))
      assert(ucf.managed_entry?('lib'))
      assert(ucf.managed_entry?('lIb/'))
      refute(ucf.reserved_entry?('META-INF'))
      refute(ucf.reserved_entry?('src'))
      refute(ucf.reserved_entry?('test'))
      refute(ucf.reserved_entry?('lib'))

      assert_equal(11, ucf.managed_entries.length)
      assert_equal(['index.html', 'META-INF/container.xml',
        'META-INF/manifest.xml', 'META-INF/metadata.xml',
        'META-INF/signatures.xml', 'META-INF/encryption.xml',
        'META-INF/rights.xml', 'META-INF', 'src', 'test', 'lib'],
        ucf.managed_entry_names)

      refute(ucf.managed_entry?('This_should_fail'))
      refute(ucf.managed_entry?('META_INF'))
      refute(ucf.managed_entry?('META_INF/'))
      refute(ucf.managed_entry?('index.htm'))
    end
  end

  # Check that nothing happens when trying to delete the mimetype file.
  def test_delete_mimetype
    UCF::File.open(UCF_EXAMPLE) do |ucf|
      assert(ucf.file.exists?('mimetype'))
      assert_nil(ucf.remove('mimetype'))
      assert(ucf.file.exists?('mimetype'))
    end
  end

  # Check that nothing happens when trying to rename the mimetype file.
  def test_rename_mimetype
    UCF::File.open(UCF_EXAMPLE) do |ucf|
      assert(ucf.file.exists?('mimetype'))
      assert_nil(ucf.rename('mimetype', 'something-else'))
      assert(ucf.file.exists?('mimetype'))
      refute(ucf.file.exists?('something-else'))
    end
  end

  # Check that nothing happens when trying to replace the contents of the
  # mimetype file.
  def test_replace_mimetype
    UCF::File.open(UCF_EXAMPLE) do |ucf|
      assert(ucf.file.exists?('mimetype'))
      assert_nil(ucf.replace('mimetype', ZIP_EMPTY))
      assert_equal('application/epub+zip', ucf.file.read('mimetype'))
    end
  end

  # Check that an exception is raised when trying to add file with a reserved
  # name.
  def test_add_reserved
    UCF::File.open(UCF_EMPTY) do |ucf|
      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.add('META-INF', ZIP_EMPTY)
      end
    end
  end

  # Check that an exception is raised when trying to add file with a reserved
  # name to a subclassed container.
  def test_subclass_add_reserved
    NewUCF.open(UCF_EMPTY) do |ucf|
      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.add('mimetype', ZIP_EMPTY)
      end

      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.add('reserved_dir', ZIP_EMPTY)
      end

      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.add('MimeType', ZIP_EMPTY)
      end

      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.add('Reserved_Dir', ZIP_EMPTY)
      end
    end
  end

  # Check that the META-INF directory is detected as non-existent when trying
  # to delete it.
  def test_delete_metainf
    UCF::File.open(UCF_EXAMPLE) do |ucf|
      assert_raises(Errno::ENOENT) do
        ucf.remove('META-INF')
      end
    end
  end

  # Check that the META-INF directory is detected as non-existent when trying
  # to rename it.
  def test_rename_metainf
    UCF::File.open(UCF_EXAMPLE) do |ucf|
      assert_raises(Errno::ENOENT) do
        ucf.rename('META-INF', 'something-else')
      end
    end
  end

  # Check that an exception is raised when trying to create a directory with a
  # reserved name.
  def test_mkdir_reserved
    UCF::File.open(UCF_EMPTY) do |ucf|
      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.mkdir('mimetype')
      end

      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.mkdir('META-INF/container.xml')
      end
    end
  end

  # Check that an exception is raised when trying to create a directory with a
  # reserved name in a subclassed container.
  def test_subclass_mkdir_reserved
    NewUCF.open(UCF_EMPTY) do |ucf|
      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.mkdir('mimetype')
      end

      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.mkdir('index.html')
      end

      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.mkdir('reserved_dir')
      end

      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.mkdir('Reserved_Dir')
      end

      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.mkdir('META-INF/container.xml')
      end
    end
  end

  # Check that a file cannot be renamed to one of the reserved names.
  def test_rename_to_reserved
    UCF::File.open(UCF_EXAMPLE) do |ucf|
      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.rename('dir/code.rb', 'mimetype')
      end
    end
  end

  # Check that a file cannot be renamed to one of the reserved names in a
  # subclassed container.
  def test_subclass_rename_to_reserved
    NewUCF.open(UCF_EXAMPLE) do |ucf|
      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.rename('dir/code.rb', 'mimetype')
      end

      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.rename('dir', 'reserved_dir')
      end
    end
  end

  # Check that the ruby-like File and Dir classes respect reserved and managed
  # names.
  def test_file_dir_ops_reserved
    UCF::File.open(UCF_EMPTY) do |ucf|
      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.file.open('META-INF', 'w') do |f|
          f.puts 'TESTING'
        end
      end

      ucf.file.open('mimetype') do |f|
        assert_equal('application/epub+zip', f.read)
      end

      ucf.file.delete('mimetype')
      assert(ucf.file.exists?('mimetype'))
    end
  end

  # Check that the ruby-like File and Dir classes respect reserved names in a
  # subclassed container.
  def test_subclass_file_dir_ops_reserved
    NewUCF.open(UCF_EMPTY) do |ucf|
      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.file.open('META-INF', 'w') do |f|
          f.puts 'TESTING'
        end
      end

      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.file.open('TEST', 'w') do |f|
          f.puts 'TESTING'
        end
      end

      ucf.file.open('mimetype') do |f|
        assert_equal('application/epub+zip', f.read)
      end

      ucf.file.delete('mimetype')
      assert(ucf.file.exists?('mimetype'))

      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.dir.mkdir('index.html')
      end

      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.dir.mkdir('reserved_dir')
      end

      assert_raises(ZipContainer::ReservedNameClashError) do
        ucf.dir.mkdir('Reserved_Dir')
      end
    end
  end

end
