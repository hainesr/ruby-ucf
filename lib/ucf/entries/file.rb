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

  # A ManagedFile is used to reserve a filename in a Container namespace.
  class ManagedFile < ManagedEntry

    # :call-seq:
    #   new(name, required = false, validation_proc = nil) -> ManagedFile
    #
    # Create a new ManagedFile with the supplied name and whether it is
    # required to exist or not.
    #
    # If supplied <tt>validation_proc</tt> should be a Proc that takes a
    # single parameter and returns +true+ or +false+ depending on whether the
    # contents of the file were validated or not.
    #
    # For more complex content validation subclasses may override the validate
    # method.
    #
    # The following example creates a ManagedFile that is not required to be
    # present in the container, but if it is, its contents must be the single
    # word "Boo!".
    #
    #  valid = Proc.new { |contents| contents == "Boo!" }
    #  ManagedFile.new("Surprize.txt", false, valid)
    def initialize(name, required = false, validation_proc = nil)
      super(name, required)

      @validation_proc = validation_proc.is_a?(Proc) ? validation_proc : nil
    end

    # :call-seq:
    #   verify!
    #
    # Verify this ManagedFile for correctness. The contents are validated if
    # required.
    #
    # A MalformedUCFError is raised if it does not pass verification.
    def verify!
      super
      unless (exists? ? validate : true)
        raise MalformedUCFError.new("The contents of file '#{full_name}' do "\
          "not pass validation.")
      end
    end

    protected

    # :call-seq:
    #   validate -> boolean
    #
    # Validate the contents of this ManagedFile. By default this methods uses
    # the validation Proc supplied on object initialization if there is one.
    # If not it simply returns true (no validation was required).
    #
    # For complex validations of content subclasses can override this method.
    def validate
      @validation_proc.nil? ? true : @validation_proc.call(contents)
    end

    private

    # Grab the contents of this ManagedFile
    def contents
      container.read(full_name)
    end

  end
end
