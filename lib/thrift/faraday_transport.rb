require 'thrift'
require 'faraday'
require 'stringio'

module Thrift
  # Public: Faraday transport for Thrift
  class FaradayTransport < Thrift::BaseTransport
    VERSION = Gem.loaded_specs['thrift-faraday_transport'].version.to_s
    BASE_HEADERS = { 'Content-Type' => 'application/x-thrift' }.freeze
    DEFAULT_PATH = '/'.freeze

    attr_reader :faraday_connection, :path

    # Public: Initialize new FaradayTransport
    #
    # faraday_connection - instance of Faraday::Connection
    # path - optional endpoin path (Default: '/')
    #
    # Returns new Thrift::FaradayTransport
    def initialize(faraday_connection, path: DEFAULT_PATH)
      @faraday_connection = faraday_connection
      @path = path
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
      response = @faraday_connection.post(path) do |request|
        request.body = @out_buffer
        request.headers.merge!(BASE_HEADERS)
      end
      @in_buffer = StringIO.new(response.body)
    ensure
      flush_out_buffer
    end

    private

    def flush_out_buffer
      @out_buffer = Bytes.empty_byte_buffer
    end
  end
end
