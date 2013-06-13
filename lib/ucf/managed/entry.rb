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

  # ManagedEntry is the superclass of ManagedDirectory and ManagedFile. It
  # should not be used directly but may be subclassed if necessary.
  class ManagedEntry

    # :call-seq:
    #   new(name, required) -> ManagedEntry
    #
    # Create a new ManagedEntry with the supplied name. The entry should also
    # be marked as required or not.
    def initialize(name, required)
      @parent = nil
      @name = name
      @required = required
    end

    # :call-seq:
    #   name -> string
    #
    # The fully qualified name of this ManagedEntry.
    def name
      @parent.is_a?(Container) ? @name : "#{@parent.name}/#{@name}"
    end

    # :call-seq:
    #   required? -> true or false
    #
    # Is this ManagedEntry required to be present according to the
    # specification of its Container?
    def required?
      @required
    end

    # :call-seq:
    #   exists? -> true or false
    #
    # Does this ManagedEntry exist in the Container?
    def exists?
      container.entries.each do |entry|
        test = (entry.ftype == :directory ? "#{name}/" : name)
        return true if entry.name == test
      end

      false
    end

    # :stopdoc:
    # Allows the object in which this entry has been registered in to tell it
    # who it is.
    def parent=(parent)
      @parent = parent
    end
    # :startdoc:

    # :call-seq:
    #   verify!
    #
    # Verify this ManagedEntry raising a MalformedUCFError if it fails. See
    # the protected method verify for more details.
    def verify!
      unless verify
        raise MalformedUCFError.new("Entry '#{name}' is required but missing.")
      end
    end

    protected

    # :call-seq:
    #   verify -> true or false
    #
    # Verify this ManagedEntry by checking that this file exists if it is
    # required according to its Container specification.
    #
    # Subclasses of ManagedEntry, see ManagedDirectory and ManagedFile for
    # example, should override this method with any extra checks that need to
    # be done for verification.
    def verify
      !@required || exists?
    end

    # :call-seq:
    #   container -> Container
    #
    # Return the Container that this ManagedEntry resides in.
    def container
      @parent.is_a?(Container) ? @parent : @parent.container
    end

  end
end
