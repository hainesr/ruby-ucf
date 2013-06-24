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

require 'zip/zip_entry'

module UCF

  # This module provides support for reserved names.
  module ReservedNames

    # :call-seq:
    #   reserved_names -> Array
    #
    # Return a list of reserved file and directory names for this UCF
    # document.
    #
    # Reserved files and directories must be accessed directly by methods
    # within Container (or subclasses of Container). This is because they are
    # fundamental to the format and might need to exhibit certain properties
    # (such as no compression) that must be preserved. The "mimetype" file is
    # an example of such a reserved entry.
    #
    # To add a reserved name to a subclass of Container simply add it to the
    # list in the constructor (you must call the super constructor first!):
    #
    #  class MyContainer < UCF::Container
    #    def initialize(filename)
    #      super(filename)
    #
    #      register_reserved_name("my_reserved_name")
    #    end
    #  end
    def reserved_names
      @reserved_names ||= []
    end

    # :call-seq:
    #   reserved_entry?(entry) -> boolean
    #
    # Is the given entry in the reserved list of names? A String or a
    # Zip::ZipEntry object can be passed in here.
    def reserved_entry?(entry)
      name = entry.kind_of?(::Zip::ZipEntry) ? entry.name : entry
      name.chop! if name.end_with? "/"
      reserved_names.map { |n| n.downcase }.include? name.downcase
    end

    protected

    # :call-seq:
    #   register_reserved_name(name)
    #
    # Add a reserved name to the list.
    def register_reserved_name(name)
      @reserved_names ||= []
      @reserved_names << name unless @reserved_names.include? name
    end
  end
end
