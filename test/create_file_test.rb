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

class TestCreateFile < Minitest::Test

  # Check creation of standard empty ucf files.
  def test_create_standard_file
    Dir.mktmpdir do |dir|
      filename = File.join(dir, "test.ucf")

      UCF::File.create(filename) do |c|
        assert(c.on_disk?)
        refute(c.in_memory?)

        assert(c.find_entry("mimetype").local_header_offset == 0)
      end

      UCF::File.verify!(filename)
    end
  end

  # Check creation of empty ucf files with a different mimetype.
  def test_create_mimetype_file
    mimetype = "application/x-something-really-odd"

    Dir.mktmpdir do |dir|
      filename = File.join(dir, "test.ucf")

      UCF::File.create(filename, mimetype) do |c|
        assert(c.on_disk?)
        refute(c.in_memory?)

        assert(c.find_entry("mimetype").local_header_offset == 0)

        assert_equal(mimetype, c.read("mimetype"))
      end

      UCF::File.verify!(filename)
    end
  end

  # Check creation of stuff in ucf files. Check the commit status a few times
  # to ensure that what we expect to happen, happens.
  def test_create_contents_file
    Dir.mktmpdir do |dir|
      filename = File.join(dir, "test.ucf")

      UCF::File.create(filename) do |ucf|
        assert(ucf.on_disk?)
        refute(ucf.in_memory?)

        ucf.file.open("test.txt", "w") do |f|
          f.print "testing"
        end

        assert(ucf.commit_required?)
        assert(ucf.commit)
        refute(ucf.commit_required?)
        refute(ucf.commit)

        ucf.dir.mkdir("dir1")
        ucf.mkdir("dir2")

        assert(ucf.commit_required?)
        assert(ucf.commit)
        refute(ucf.commit_required?)
        refute(ucf.commit)

        ucf.comment = "A comment!"

        assert(ucf.commit_required?)
        assert(ucf.commit)
        refute(ucf.commit_required?)
        refute(ucf.commit)
      end

      UCF::File.open(filename) do |ucf|
        assert(ucf.on_disk?)
        refute(ucf.in_memory?)

        assert(ucf.file.exists?("test.txt"))
        assert(ucf.file.exists?("dir1"))
        assert(ucf.file.exists?("dir2"))
        refute(ucf.file.exists?("dir3"))

        text = ucf.file.read("test.txt")
        assert_equal("testing", text)

        assert_equal("A comment!", ucf.comment)

        refute(ucf.commit_required?)
        refute(ucf.commit)
      end
    end
  end

end
