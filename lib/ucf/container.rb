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

  # This class represents a UCF document in PK Zip format. See
  # {the specification}[https://learn.adobe.com/wiki/display/PDFNAV/Universal+Container+Format]
  # for more details.
  #
  # This class provides most of the facilities of the <tt>Zip::ZipFile</tt>
  # class in the rubyzip gem. Please also consult the
  # {rubyzip documentation}[http://rubydoc.info/gems/rubyzip/0.9.9/frames]
  # alongside these pages.
  #
  # There are code examples available with the source code of this library.
  class Container

    extend Forwardable
    def_delegators :@zipfile, :comment, :comment=, :commit_required?, :each,
      :entries, :extract, :find_entry, :get_entry, :get_input_stream, :glob,
      :name, :read, :size

    private_class_method :new

    # The mime-type of this UCF document. By default this is
    # "application/epub+zip".
    attr_reader :mimetype

    # :stopdoc:
    DEFAULT_MIMETYPE = "application/epub+zip"

    # The reserved mimetype file name for standard UCF documents.
    MIMETYPE_FILE = "mimetype"

    def initialize(document)
      @zipfile = open_document(document)
      check_document!

      @mimetype = read_mimetype
      @on_disk = true

      # Register the META-INF managed directory and initialize managed files.
      @directories = [MetaInf.new]
      @files = []

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
    #   Container.create(filename, mimetype = "application/epub+zip") -> document
    #   Container.create(filename, mimetype = "application/epub+zip") {|document| ...}
    #
    # Create a new UCF document on disk with the specified mimetype.
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
    #   Container.open(filename) -> document
    #   Container.open(filename) {|document| ...}
    #
    # Open an existing UCF document from disk. It will be checked for
    # conformance to the UCF specification upon first access.
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
    # Verify that the specified UCF document conforms to the UCF
    # specification. This method returns +false+ if there are any problems at
    # all with the file (including if it cannot be found).
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
    # Verify that the specified UCF document conforms to the UCF
    # specification. This method raises exceptions when errors are found or if
    # there is something fundamental wrong with the file itself (e.g. it
    # cannot be found).
    def Container.verify!(filename)
      new(filename).close
      nil
    end

    # :call-seq:
    #   add(entry, src_path, &continue_on_exists_proc)
    #
    # Convenience method for adding the contents of a file to the UCF
    # document. If asked to add a file with a reserved name, such as the
    # special mimetype header file, this method will raise a
    # ReservedNameClashError.
    #
    # See the rubyzip documentation for details of the
    # +continue_on_exists_proc+ parameter.
    def add(entry, src_path, &continue_on_exists_proc)
      raise ReservedNameClashError.new(entry.to_s) if reserved_entry?(entry)

      @zipfile.add(entry, src_path, &continue_on_exists_proc)
    end

    # :call-seq:
    #   commit -> boolean
    #   close -> boolean
    #
    # Commits changes that have been made since the previous commit to the
    # UCF document. Returns +true+ if anything was actually done, +false+
    # otherwise.
    def commit
      return false unless commit_required?

      if on_disk?
        @zipfile.commit
      end
    end

    alias :close :commit

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
    #   file -> Zip::ZipFsFile
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
    #   in_memory? -> boolean
    #
    # Is this UCF document memory resident as opposed to stored on disk?
    def in_memory?
      !@on_disk
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
    #   on_disk? -> boolean
    #
    # Is this UCF document stored on disk as opposed to memory resident?
    def on_disk?
      @on_disk
    end

    # :call-seq:
    #   remove(entry)
    #
    # Removes the specified entry from the UCF document. If asked to remove
    # any reserved files such as the special mimetype header file this method
    # will do nothing.
    def remove(entry)
      return if reserved_entry?(entry)
      @zipfile.remove(entry)
    end

    # :call-seq:
    #   rename(entry, new_name, &continue_on_exists_proc)
    #
    # Renames the specified entry in the UCF document. If asked to rename any
    # reserved files such as the special mimetype header file this method will
    # do nothing. If asked to rename a file _to_ one of the reserved names a
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
    # Replaces the specified entry of the UCF document with the contents of
    # +src_path+ (from the file system). If asked to replace any reserved
    # files such as the special mimetype header file this method will do
    # nothing.
    def replace(entry, src_path)
      return if reserved_entry?(entry)
      @zipfile.replace(entry, src_path)
    end

    # :call-seq:
    #   reserved_files -> Array
    #
    # Return a list of reserved file names for this UCF document.
    #
    # Subclasses can add reserved files using the protected
    # register_managed_file method.
    def reserved_files
      [MIMETYPE_FILE] + @files.map { |f| f.name } +
        @directories.map { |d| d.reserved_names }.flatten
    end

    # :call-seq:
    #   reserved_directories -> Array
    #
    # Return a list of reserved directory names for this UCF document.
    #
    # Subclasses can add reserved directories using the protected
    # register_managed_directory method.
    def reserved_directories
      @directories.map { |d| d.name }
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
    # Return a textual summary of this UCF document.
    def to_s
      @zipfile.to_s + " - #{@mimetype}"
    end

    protected

    # :call-seq:
    #   register_managed_directory(directory)
    #
    # Register a ManagedDirectory. A ManagedDirectory is used to both reserve
    # the name of a directory in the container namespace and act as an
    # interface to the (possibly) managed files within it.
    def register_managed_directory(directory)
      unless directory.is_a? ::UCF::ManagedDirectory
        raise ArgumentError.new("The supplied parameter must be of type ManagedDirectory (or a subclass).")
      end

      @directories << directory
    end

    # :call-seq:
    #   register_managed_file(file)
    #
    # Register a ManagedFile. A ManagedFile is used to reserve the name of a
    # file in the container namespace.
    def register_managed_file(file)
      unless file.is_a? ::UCF::ManagedFile
        raise ArgumentError.new("The supplied parameter must be of type ManagedFile (or a subclass).")
      end

      @files << file
    end

    private

    def open_document(document)
      ::Zip::ZipFile.new(document)
    end

    def check_document!
      # Check mimetype file is present and correct.
      entry = @zipfile.find_entry(MIMETYPE_FILE)

      raise MalformedUCFError.new("'mimetype' file is missing.") if entry.nil?
      if entry.localHeaderOffset != 0
        raise MalformedUCFError.new("'mimetype' file is not at offset 0 in the archive.")
      end
      if entry.compression_method != ::Zip::ZipEntry::STORED
        raise MalformedUCFError.new("'mimetype' file is compressed.")
      end

      true
    end

    def read_mimetype
      @zipfile.read(MIMETYPE_FILE)
    end

    public

    # Lots of extra docs out of the way at the end here...

    ##
    # :method: comment
    # :call-seq:
    #   comment -> String
    #
    # Returns the UCF document comment, if it has one.

    ##
    # :method: comment=
    # :call-seq:
    #   comment = comment
    #
    # Set the UCF document comment to the new value.

    ##
    # :method: commit_required?
    # :call-seq:
    #   commit_required? -> boolean
    #
    # Returns +true+ if any changes have been made to this UCF document since
    # the last commit, +false+ otherwise.

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
    # :method:
    # :call-seq:
    #   entries -> Enumerable
    #
    # Returns an Enumerable containing all the entries in the UCF Document.
    # The entry objects returned by this method are Zip::ZipEntry objects.
    # Please see the rubyzip documentation for details.

    ##
    # :method: extract
    # :call-seq:
    #   extract(entry, dest_path, &on_exists_proc)
    #
    # Extracts the specified entry of the UCF document to +dest_path+.
    #
    # See the rubyzip documentation for details of the +on_exists_proc+
    # parameter.

    ##
    # :method: find_entry
    # :call-seq:
    #   find_entry(entry) -> Zip::ZipEntry
    #
    # Searches for entries within the UCF document with the specified name.
    # Returns +nil+ if no entry is found. See also +get_entry+.

    ##
    # :method: get_entry
    # :call-seq:
    #   get_entry(entry) -> Zip::ZipEntry
    #
    # Searches for an entry within the UCF document in a similar manner to
    # +find_entry+, but throws +Errno::ENOENT+ if no entry is found.

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
    # Searches for entries within the UCF document that match the given glob.
    #
    # See the rubyzip documentation for details of the parameters that can be
    # passed in.

    ##
    # :method: name
    # :call-seq:
    #   name -> String
    #
    # Returns the filename of this UCF document.

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
