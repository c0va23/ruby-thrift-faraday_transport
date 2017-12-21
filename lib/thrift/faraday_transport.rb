require 'thrift'
require 'faraday'
require 'stringio'

module Thrift
  # Public: Faraday transport for Thrift
  class FaradayTransport < Thrift::BaseTransport
    VERSION = Gem.loaded_specs['thrift-faraday_transport'].version.to_s
    BASE_HEADERS = { 'Content-Type' => 'application/x-thrift' }.freeze

    # @return [Faraday::Connection] attribute faraday_connection
    attr_reader :faraday_connection

    # Initialize new Faraday transport
    #
    # @param faraday_connection [Faraday::Connection]
    #
    # @return [Thrift::FaradayTransport]
    def initialize(faraday_connection)
      @faraday_connection = faraday_connection
      flush_out_buffer
    end

    def open?
      true
    end

    def write(data)
      @out_buffer << data
    end

    def read(size)
      @in_buffer.read(size)
    end

    def flush
      response = @faraday_connection.post do |request|
        request.body = @out_buffer
        request.headers.merge!(BASE_HEADERS)
      end
      body = Bytes.force_binary_encoding(response.body)
      @in_buffer = StringIO.new(body)
    ensure
      flush_out_buffer
    end

    private

    def flush_out_buffer
      @out_buffer = Bytes.empty_byte_buffer
    end
  end
end
