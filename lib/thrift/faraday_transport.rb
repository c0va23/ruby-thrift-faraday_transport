require 'thrift'

module Thrift
  # Public: Faraday transport for Thrift
  class FaradayTransport < Thrift::BaseTransport
    VERSION = Gem.loaded_specs['thrift-faraday_transport'].version.to_s

    attr_reader :faraday_connection, :path

    # Public: Initialize new FaradayTransport
    #
    # faraday_connection - instance of Faraday::Connection
    #
    # Returns new Thrift::FaradayTransport
    def initialize(faraday_connection, path: nil)
      @faraday_connection = faraday_connection
      @path = path
    end
  end
end
