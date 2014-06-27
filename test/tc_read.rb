# Copyright (c) 2013, 2014 The University of Manchester, UK.
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

require 'test/unit'
require 'ucf'

class TestRead < Test::Unit::TestCase

  # Check that the null file does not verify.
  def test_verify_null_file
    assert_raise(Zip::ZipError) do
      UCF::File.verify!($file_null)
    end

    refute(UCF::File.verify($file_null))
  end

  # Check that the empty ucf file does verify.
  def test_verify_empty_ucf
    assert_nothing_raised(ZipContainer::MalformedContainerError, Zip::ZipError) do
      UCF::File.verify!($ucf_empty)
    end

    assert(UCF::File.verify($ucf_empty))
  end

  # Check that the example ucf file does verify.
  def test_verify_example_ucf
    assert_nothing_raised(ZipContainer::MalformedContainerError, Zip::ZipError) do
      UCF::File.verify!($ucf_example)
    end

    assert(UCF::File.verify($ucf_example))
  end

  # Check that the empty zip file does not verify.
  def test_verify_empty_zip
    assert_raise(ZipContainer::MalformedContainerError) do
      UCF::File.verify!($zip_empty)
    end

    refute(UCF::File.verify($zip_empty))
  end

  # Check that a compressed mimetype file is detected.
  def test_verify_compressed_mimetype
    assert_raise(ZipContainer::MalformedContainerError) do
      UCF::File.verify!($ucf_compressed_mimetype)
    end

    refute(UCF::File.verify($ucf_compressed_mimetype))
  end

  # Check the raw mimetype bytes
  def test_raw_mimetypes
    empty_ucf = File.read($ucf_empty)
    assert_equal("application/epub+zip", empty_ucf[38..57])

    compressed_mimetype = File.read($ucf_compressed_mimetype)
    assert_not_equal("application/epub+zip", compressed_mimetype[38..57])
  end

  # Check reading files out of a ucf file and make sure we don't change it.
  def test_read_files_from_ucf
    assert_nothing_raised(ZipContainer::MalformedContainerError, Zip::ZipError) do
      UCF::File.open($ucf_example) do |ucf|
        assert(ucf.on_disk?)
        refute(ucf.in_memory?)

        assert(ucf.file.exists?("greeting.txt"))

        greeting = ucf.file.read("greeting.txt")
        assert_equal("Hello, World!\n", greeting)

        assert(ucf.file.exists?("dir"))
        assert(ucf.file.directory?("dir"))

        assert(ucf.file.exists?("dir/code.rb"))

        assert_equal("This is an example UCF file!", ucf.comment)

        refute(ucf.commit_required?)
        refute(ucf.commit)
      end
    end
  end

end
