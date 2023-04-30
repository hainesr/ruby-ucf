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

begin
  require 'nokogiri'
rescue LoadError
  # We don't care if there's no nokogiri but can't validate things without it.
end

module UCF
  # This is a subclass of ManagedDirectory to represent the META-INF directory
  # in a basic UCF Document.
  class MetaInf < ZipContainer::ManagedDirectory
    SCHEMA_DIR = ::File.join(::File.dirname(__FILE__), 'schema')
    CONTAINER_SCHEMA = ::File.join(SCHEMA_DIR, 'container.rng')
    MANIFEST_SCHEMA = ::File.join(SCHEMA_DIR, 'OpenDocument-manifest-schema-v1.0-os.rng')

    # :call-seq:
    #   new -> MetaInf
    #
    # Create a standard META-INF ManagedDirectory.
    def initialize
      super('META-INF', :required => false, :entries =>
        [
          File.new('container.xml', CONTAINER_SCHEMA),
          File.new('manifest.xml', MANIFEST_SCHEMA),
          File.new('metadata.xml'),
          File.new('signatures.xml'),
          File.new('encryption.xml'),
          File.new('rights.xml')
        ]
      )
    end

    class File < ZipContainer::ManagedFile
      def initialize(name, schema = nil)
        super(name, :required => false)

        @schema = nil
        return unless defined?(::Nokogiri)

        @schema = schema.nil? ? nil : Nokogiri::XML::RelaxNG(::File.open(schema))
      end

      protected

      def validate
        @schema.nil? ? true : @schema.validate(Nokogiri::XML(contents)) == []
      end
    end
  end
end
