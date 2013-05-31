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

  # This class represents a UCF file in PK Zip format. See
  # https://learn.adobe.com/wiki/display/PDFNAV/Universal+Container+Format
  # for more details.
  #
  # This class mostly provides all the facilities of the <tt>Zip::ZipFile</tt>
  # class in the rubyzip gem. Please also consult the rubyzip documentation:
  # http://rubydoc.info/gems/rubyzip/0.9.9/frames
  #
  # There are code examples available with the source code of this library.
  class Container

    extend Forwardable
    def_delegators :@zipfile, :close, :comment, :commit, :each, :extract,
      :find_entry, :get_entry, :get_input_stream, :glob, :name, :read, :size

    private_class_method :new

    # The mime-type of this UCF file. By default this is
    # "application/epub+zip".
    attr_reader :mimetype

    # :stopdoc:
    DEFAULT_MIMETYPE = "application/epub+zip"

    # Reserved file and directory names for the standard UCF.
    MIMETYPE_FILE = "mimetype"
    META_INF_DIR = "META-INF"

    ERR_MT_NONE = "'mimetype' file is missing."
    ERR_MT_BAD_OFF = "'mimetype' file is not at offset 0 in the archive."
    ERR_MT_BAD_COMP = "'mimetype' file is compressed."

    def initialize(filename)
      @zipfile = open_and_check_ucf(filename)
      @mimetype = read_mimetype

      # Here we fake up the connection to the rubyzip filesystem classes so
      # that they also respect the reserved names that we define.
      mapped_zip = ::Zip::ZipFileSystem::ZipFileNameMapper.new(self)
      @fs_dir  = ::Zip::ZipFileSystem::ZipFsDir.new(mapped_zip)
      @fs_file = ::Zip::ZipFileSystem::ZipFsFile.new(mapped_zip)
      @fs_dir.file = @fs_file
      @fs_file.dir = @fs_dir
    end
    # :startdoc:

    # :call-seq:
    #   Container.create(filename, mimetype = "application/epub+zip") -> container
    #   Container.create(filename, mimetype = "application/epub+zip") {|container| ...}
    #
    # Create a new UCF file on disk with the specified mimetype.
    def Container.create(filename, mimetype = DEFAULT_MIMETYPE, &block)
      ::Zip::ZipOutputStream.open(filename) do |stream|
        stream.put_next_entry(MIMETYPE_FILE, nil, nil, ::Zip::ZipEntry::STORED)
        stream.write mimetype
      end

      Container.open(filename, &block)
    end

    # :call-seq:
    #   Container.each_entry -> Enumerator
    #   Container.each_entry {|entry| ...}
    #
    # Iterate over the entries in the UCF document. The entry objects returned
    # by this method are Zip::ZipEntry objects. Please see the rubyzip
    # documentation for details.
    def Container.each_entry(filename, &block)
      c = new(filename)

      if block_given?
        begin
          c.each(&block)
        ensure
          c.close
        end
      end

      c.each
    end

    # :call-seq:
    #   Container.open(filename) -> container
    #   Container.open(filename) {|container| ...}
    #
    # Open an existing UCF file from disk. It will be checked for conformance
    # to the UCF specification upon first access.
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
      new(filename).close
      nil
    end

    # :call-seq:
    #   add(entry, src_path, &continue_on_exists_proc)
    #
    # Convenience method for adding the contents of a file to the UCF file. If
    # asked to add a file with a reserved name, such as the special mimetype
    # header file, this method will raise a ReservedNameClashError.
    #
    # See the rubyzip documentation for details of the
    # +continue_on_exists_proc+ parameter.
    def add(entry, src_path, &continue_on_exists_proc)
      raise ReservedNameClashError.new(entry.to_s) if reserved_entry?(entry)

      @zipfile.add(entry, src_path, &continue_on_exists_proc)
    end

    # :call-seq:
    #   dir -> Zip::ZipFsDir
    #
    # Returns an object which can be used like ruby's built in +Dir+ (class)
    # object, except that it works on the UCF document on which this method is
    # invoked.
    #
    # See the rubyzip documentation for details.
    def dir
      @fs_dir
    end

    # :call-seq:
    #   dir -> Zip::ZipFsFile
    #
    # Returns an object which can be used like ruby's built in +File+ (class)
    # object, except that it works on the UCF document on which this method is
    # invoked.
    #
    # See the rubyzip documentation for details.
    def file
      @fs_file
    end

    # :call-seq:
    #   get_output_stream(entry, permission = nil) -> stream
    #   get_output_stream(entry, permission = nil) {|stream| ...}
    #
    # Returns an output stream to the specified entry. If a block is passed
    # the stream object is passed to the block and the stream is automatically
    # closed afterwards just as with ruby's built-in +File.open+ method.
    #
    # See the rubyzip documentation for details of the +permission_int+
    # parameter.
    def get_output_stream(entry, permission = nil, &block)
      raise ReservedNameClashError.new(entry.to_s) if reserved_entry?(entry)

      @zipfile.get_output_stream(entry, permission, &block)
    end

    # :call-seq:
    #   mkdir(name, permission = 0755)
    #
    # Creates a directory in the UCF document. If asked to create a directory
    # with a reserved name this method will raise a ReservedNameClashError.
    #
    # The new directory will be created with the supplied unix-style
    # permissions. The default (+0755+) is owner read, write and list; group
    # read and list; and world read and list.
    def mkdir(name, permission = 0755)
      raise ReservedNameClashError.new(name) if reserved_entry?(name)

      @zipfile.mkdir(name, permission)
    end

    # :call-seq:
    #   remove(entry)
    #
    # Removes the specified entry. If asked to remove any reserved files such
    # as the special mimetype header file this method will do nothing.
    def remove(entry)
      return if reserved_entry?(entry)
      @zipfile.remove(entry)
    end

    # :call-seq:
    #   rename(entry, new_name, &continue_on_exists_proc)
    #
    # Renames the specified entry. If asked to rename any reserved files such
    # as the special mimetype header file this method will do nothing. If
    # asked to rename a file _to_ one of the reserved names a
    # ReservedNameClashError is raised.
    #
    # See the rubyzip documentation for details of the
    # +continue_on_exists_proc+ parameter.
    def rename(entry, new_name, &continue_on_exists_proc)
      return if reserved_entry?(entry)
      raise ReservedNameClashError.new(new_name) if reserved_entry?(new_name)

      @zipfile.rename(entry, new_name, &continue_on_exists_proc)
    end

    # :call-seq:
    #   replace(entry, src_path)
    #
    # Replaces the specified entry with the contents of +src_path+ (from the
    # file system). If asked to replace any reserved files such as the special
    # mimetype header file this method will do nothing.
    def replace(entry, src_path)
      return if reserved_entry?(entry)
      @zipfile.replace(entry, src_path)
    end

    # :call-seq:
    #   reserved_files -> Array
    #
    # Return a list of reserved file names for this UCF document.
    #
    # When creating a more specialized sub-class of this class then this
    # method should be overridden to add any extra reserved file names.
    def reserved_files
      [MIMETYPE_FILE]
    end

    # :call-seq:
    #   reserved_directories -> Array
    #
    # Return a list of reserved directory names for this UCF document.
    #
    # When creating a more specialized sub-class of this class then this
    # method should be overridden to add any extra reserved directory names.
    def reserved_directories
      [META_INF_DIR]
    end

    # :call-seq:
    #   reserved_entry?(entry) -> boolean
    #
    # Is the given entry name in the reserved list of file or directory names?
    def reserved_entry?(entry)
      name = entry.kind_of?(::Zip::ZipEntry) ? entry.name : entry
      name.chop! if name.end_with? "/"
      reserved_names.map { |n| n.downcase }.include? name.downcase
    end

    # :call-seq:
    #   reserved_names -> Array
    #
    # Return a list of reserved file and directory names for this UCF
    # document.
    #
    # In practice this method simply returns the joined lists of reserved file
    # and directory names.
    def reserved_names
      reserved_files + reserved_directories
    end

    # :call-seq:
    #   to_s -> String
    #
    # Return a String representation of this UCF file.
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

    public

    # Lots of extra docs out of the way at the end here...

    ##
    # :method: close
    # :call-seq:
    #   close
    #
    # Closes the UCF file committing any changes that have been made.

    ##
    # :method: comment
    # :call-seq:
    #   comment -> String
    #
    # Returns the UCF file comment, if it has one.

    ##
    # :method: commit
    # :call-seq:
    #   commit
    #
    # Commits changes that have been made since the previous commit to the
    # UCF file.

    ##
    # :method: each
    # :call-seq:
    #   each -> Enumerator
    #   each {|entry| ...}
    #
    # Iterate over the entries in the UCF document. The entry objects returned
    # by this method are Zip::ZipEntry objects. Please see the rubyzip
    # documentation for details.

    ##
    # :method: extract
    # :call-seq:
    #   extract(entry, dest_path, &on_exists_proc)
    #
    # Extracts the specified entry to +dest_path+.
    #
    # See the rubyzip documentation for details of the +on_exists_proc+
    # parameter.

    ##
    # :method: find_entry
    # :call-seq:
    #   find_entry(entry) -> Zip::ZipEntry
    #
    # Searches for entries with the specified name. Returns +nil+ if no entry
    # is found. See also +get_entry+.

    ##
    # :method: get_entry
    # :call-seq:
    #   get_entry(entry) -> Zip::ZipEntry
    #
    # Searches for an entry like +find_entry+, but throws +Errno::ENOENT+ if
    # no entry is found.

    ##
    # :method: get_input_stream
    # :call-seq:
    #   get_input_stream(entry) -> stream
    #   get_input_stream(entry) {|stream| ...}
    #
    # Returns an input stream to the specified entry. If a block is passed the
    # stream object is passed to the block and the stream is automatically
    # closed afterwards just as with ruby's built in +File.open+ method.

    ##
    # :method: glob
    # :call-seq:
    #   glob(*args) -> Array of Zip::ZipEntry
    #   glob(*args) {|entry| ...}
    #
    # Searches for entries given a glob.
    #
    # See the rubyzip documentation for details of the parameters that can be
    # passed in.

    ##
    # :method: name
    # :call-seq:
    #   name -> String
    #
    # Returns the filename of this UCF file.

    ##
    # :method: read
    # :call-seq:
    #   read(entry) -> String
    #
    # Returns a string containing the contents of the specified entry.

    ##
    # :method: size
    # :call-seq:
    #   size -> int
    #
    # Returns the number of entries in the UCF document.

  end
end
