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

#
module UCF

  # A ManagedDirectory acts as the interface to a set of (possibly) managed
  # files within it and also reserves the directory name in the Container
  # namespace.
  #
  # Once a ManagedDirectory is registered in a Container then only it can be
  # used to write to its contents.
  class ManagedDirectory < ManagedEntry

    # :call-seq:
    #   new(name, required = false) -> ManagedDirectory
    #
    # Create a new ManagedDirectory with the supplied name and whether it is
    # required to exist or not.
    def initialize(name, required = false)
      super(name, required)

      @files = []
    end

    # :call-seq:
    #   reserved_files -> Array
    #
    # Return a list of reserved file names for this ManagedDirectory.
    #
    # Subclasses can add reserved files using the protected
    # register_managed_file method.
    def reserved_files
      @files.map { |f| f.name }
    end

    # :call-seq:
    #   reserved_names -> Array
    #
    # Return a list of reserved file and directory names for this
    # ManagedDirectory
    #
    # In practice this method simply returns the joined lists of reserved file
    # and directory names.
    def reserved_names
      reserved_files
    end

    # :call-seq:
    #   verify -> true or false
    #
    # Verify this ManagedDirectory for correctness. ManagedFiles registered
    # within it are verified recursively.
    def verify
      super && @files.inject(true) { |r, f| r && f.verify }
    end

    protected

    # :call-seq:
    #   register_managed_file(file)
    #
    # Register a ManagedFile. A ManagedFile is used to reserve the name of a
    # file in the namespaces of both this ManagedDirectory and its Container.
    def register_managed_file(file)
      unless file.is_a? ManagedFile
        if file.is_a? String
          file = ManagedFile.new(file)
        else
          raise ArgumentError.new("The supplied parameter must be a String or a ManagedFile (or a subclass).")
        end
      end

      file.parent = self
      @files << file
    end

  end
end
