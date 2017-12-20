require 'thrift'
require 'faraday'
require 'stringio'

module Thrift
  # Public: Faraday transport for Thrift
  class FaradayTransport < Thrift::BaseTransport
    VERSION = Gem.loaded_specs['thrift-faraday_transport'].version.to_s
    BASE_HEADERS = { 'Content-Type' => 'application/x-thrift' }.freeze
    DEFAULT_PATH = '/'.freeze

    attr_reader :faraday_connection

    # Public: Initialize new FaradayTransport
    #
    # faraday_connection - instance of Faraday::Connection
    #
    # Returns new Thrift::FaradayTransport
    def initialize(faraday_connection, path: nil)
      @faraday_connection = faraday_connection
      @path = path
      @outbuf = Bytes.empty_byte_buffer
    end

    def open?
      true
    end

    def write(data)
      @outbuf << data
    end

    def read(size)
      @inbuf.read(size)
    end

    def flush
      response = @faraday_connection.post(path) do |request|
        request.body = @outbuf
        request.headers.merge!(BASE_HEADERS)
      end
      @inbuf = StringIO.new(response.body)
    end

    def path
      @path || DEFAULT_PATH
    end
  end
end
