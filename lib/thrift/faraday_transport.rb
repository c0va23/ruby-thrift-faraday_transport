require 'thrift'
require 'faraday'
require 'stringio'

module Thrift
  # Faraday HTTP-transport for Thrift
  class FaradayTransport < Thrift::BaseTransport
    # Gem trhfit-faraday_transport version
    VERSION = Gem.loaded_specs['thrift-faraday_transport'].version.to_s
    # Base headers for response
    BASE_HEADERS = { 'Content-Type' => 'application/x-thrift' }.freeze

    # Unexpected HTTP code raise #flush when HTTP respond with not 200 status
    class UnexpectedHTTPCode < TransportException
      # Initialize new UnexpectedHTTPCode
      #
      # @param http_code [Integer] - response http code
      def initialize(http_code)
        super(TransportException::UNKNOWN, "Invalid HTTP code #{http_code}")
        @http_code = http_code
      end
    end

    # Faraday exception raise #flush
    class FaradayException < TransportException
      # Initialize new FaradayException
      #
      # @param faraday_exception [Faraday::ClientError]
      def initialize(faraday_exception)
        super(TransportException::UNKNOWN, faraday_exception.inspect)
      end
    end

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

    # Perform HTTP request. Implement Thrift::BaseTransport#flush
    #
    # @raise [UnexpectedHTTPCode] when HTTP server respond with not 200 status
    # @raise [FaradayException] on Faraday client exception
    def flush
      response = perform_request
      raise UnexpectedHTTPCode, response.status if response.status != 200
      body = Bytes.force_binary_encoding(response.body)
      @in_buffer = StringIO.new(body)
    ensure
      flush_out_buffer
    end

    private

    def flush_out_buffer
      @out_buffer = Bytes.empty_byte_buffer
    end

    def perform_request
      @faraday_connection.post do |request|
        request.body = @out_buffer
        request.headers.merge!(BASE_HEADERS)
      end
    rescue Faraday::ClientError => e
      raise FaradayException, e
    end
  end
end
