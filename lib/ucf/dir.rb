# Copyright (c) 2014-2023 The University of Manchester, UK.
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

##
module UCF
  # This class represents a UCF document - also known as an EPUB and very
  # similar to the
  # {EPUB Open Container Format (OCF)}[http://www.idpf.org/epub/30/spec/epub30-ocf.html].
  # See the
  # {UCF specification}[https://learn.adobe.com/wiki/display/PDFNAV/Universal+Container+Format]
  # for more details.
  #
  # This class is a specialization of ZipContainer::Dir so you should see the
  # {ZipContainer documentation}[http://mygrid.github.io/ruby-zip-container/]
  # for much more information and a list of all the other methods available in
  # this class. RDoc does not list inherited methods, unfortunately.
  #
  # There are code examples available with the source code of this library.
  class Dir < ZipContainer::Dir
    private_class_method :new

    # :stopdoc:
    DEFAULT_MIMETYPE = 'application/epub+zip'

    def initialize(filename)
      super(filename)

      # Initialize the managed entries and register the META-INF directory.
      initialize_managed_entries(MetaInf.new)
    end
    # :startdoc:

    # :call-seq:
    #   create(filename) -> UCF::Dir
    #   create(filename, mimetype) -> UCF::Dir
    #   create(filename) {|ucf| ...}
    #   create(filename, mimetype) {|ucf| ...}
    #
    # Create a new UCF document directory on disk and open it for editing. A
    # custom mimetype for the container may be specified but if not the
    # default, "application/epub+zip", will be used.
    #
    # Please see the
    # {ZipContainer documentation}[http://mygrid.github.io/ruby-zip-container/]
    # for much more information and a list of all the other methods available
    # in this class. RDoc does not list inherited methods, unfortunately.
    def self.create(filename, mimetype = DEFAULT_MIMETYPE, &block)
      super(filename, mimetype, &block)
    end
  end
end
