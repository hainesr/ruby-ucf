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

require 'forwardable'
require 'zip/zipfilesystem'

module UCF

  class Container

    extend Forwardable
    def_delegators :@zipfile, :add, :close, :comment, :commit, :dir, :extract,
      :file, :find_entry, :get_entry, :get_input_stream, :get_output_stream,
      :glob, :mkdir, :name, :read

    private_class_method :new

    attr_reader :mimetype

    # :stopdoc:
    DEFAULT_MIMETYPE = "application/epub+zip"
    MIMETYPE_FILE = "mimetype"

    ERR_MT_NONE = "Not a UCF file. 'mimetype' file is missing."
    ERR_MT_BAD_OFF = "Not a UCF file. 'mimetype' file is not at offset 0."
    ERR_MT_BAD_COMP = "Not a UCF file. 'mimetype' file is compressed."

    def initialize(filename)
      @zipfile = open_and_check_ucf(filename)

      @mimetype = read_mimetype
    end
    # :startdoc:

    def Container.create(filename, mimetype = DEFAULT_MIMETYPE, &block)
      ::Zip::ZipOutputStream.open(filename) do |stream|
        stream.put_next_entry(MIMETYPE_FILE, nil, nil, ::Zip::ZipEntry::STORED)
        stream.write mimetype
      end

      Container.open(filename, &block)
    end

    def Container.open(filename, &block)
      c = new(filename)

      if block_given?
        begin
          yield c
        ensure
          c.close
        end
      end

      c
    end

    # :call-seq:
    #   Container.verify(filename) -> boolean
    #
    # Verify that the specified UCF file conforms to the UCF specification.
    # This method returns +false+ if there are any problems at all with the
    # file (including if it can't be found) or +true+ if it conforms.
    def Container.verify(filename)
      begin
        Container.verify!(filename)
      rescue
        return false
      end

      true
    end

    # :call-seq:
    #   Container.verify!(filename)
    #
    # Verify that the specified UCF file conforms to the UCF specification.
    # This method raises exceptions when errors are found or if there is
    # something fundamental wrong with the file itself (e.g. not found).
    def Container.verify!(filename)
      new(filename)
      nil
    end

    def remove(entry)
      return if mimetype_entry?(entry)
      @zipfile.remove(entry)
    end

    def rename(entry, newName, &continueOnExistsProc)
      return if mimetype_entry?(entry)
      @zipfile.rename(entry, newName, continueOnExistsProc)
    end

    def replace(entry, srcPath)
      return if mimetype_entry?(entry)
      @zipfile.replace(entry, srcPath)
    end

    def to_s
      @zipfile.to_s + " - #{@mimetype}"
    end

    private

    def open_and_check_ucf(filename)
      file = ::Zip::ZipFile.new(filename)

      # Check mimetype file is present and correct.
      entry = file.find_entry(MIMETYPE_FILE)
      raise MalformedUCFError.new(ERR_MT_NONE) if entry.nil?
      raise MalformedUCFError.new(ERR_MT_BAD_OFF) if entry.localHeaderOffset != 0
      if entry.compression_method != ::Zip::ZipEntry::STORED
        raise MalformedUCFError.new(ERR_MT_BAD_COMP)
      end

      file
    end

    def read_mimetype
      @zipfile.read(MIMETYPE_FILE)
    end

    def mimetype_entry?(entry)
      name = entry.kind_of?(ZipEntry) ? entry.name : entry
      name == MIMETYPE_FILE
    end
  end
end
