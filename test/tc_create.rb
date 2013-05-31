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

class TestCreation < Test::Unit::TestCase

  # Check creation of standard empty ucf files.
  def test_create_standard_file
    Dir.mktmpdir do |dir|
      filename = File.join(dir, "test.ucf")

      assert_nothing_raised do
        UCF::Container.create(filename) do |c|
          assert(c.on_disk?)
          refute(c.in_memory?)

          assert(c.find_entry("mimetype").localHeaderOffset == 0)
        end
      end

      assert_nothing_raised(UCF::MalformedUCFError, Zip::ZipError) do
        UCF::Container.verify!(filename)
      end
    end
  end

  # Check creation of empty ucf files with a different mimetype.
  def test_create_mimetype_file
    mimetype = "application/x-something-really-odd"

    Dir.mktmpdir do |dir|
      filename = File.join(dir, "test.ucf")

      assert_nothing_raised do
        UCF::Container.create(filename) do |c|
          assert(c.on_disk?)
          refute(c.in_memory?)

          assert(c.find_entry("mimetype").localHeaderOffset == 0)
        end
      end

      assert_nothing_raised(UCF::MalformedUCFError, Zip::ZipError) do
        UCF::Container.verify!(filename)
      end
    end
  end

  # Check creation of stuff in ucf files.
  def test_create_contents_file
    Dir.mktmpdir do |dir|
      filename = File.join(dir, "test.ucf")

      assert_nothing_raised do
        UCF::Container.create(filename) do |ucf|
          assert(ucf.on_disk?)
          refute(ucf.in_memory?)

          ucf.file.open("test.txt", "w") do |f|
            f.print "testing"
          end

          ucf.dir.mkdir("dir1")
          ucf.mkdir("dir2")

          ucf.comment = "A comment!"
        end
      end

      assert_nothing_raised(UCF::MalformedUCFError, Zip::ZipError) do
        UCF::Container.open(filename) do |ucf|
          assert(ucf.on_disk?)
          refute(ucf.in_memory?)

          assert(ucf.file.exists?("test.txt"))
          assert(ucf.file.exists?("dir1"))
          assert(ucf.file.exists?("dir2"))
          refute(ucf.file.exists?("dir3"))

          text = ucf.file.read("test.txt")
          assert_equal("testing", text)

          assert_equal("A comment!", ucf.comment)
        end
      end
    end
  end

end
