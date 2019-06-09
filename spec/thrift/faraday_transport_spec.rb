require 'spec_helper'
require 'securerandom'

RSpec.describe Thrift::FaradayTransport do
  subject { described_class.new(faraday_connection) }

  let(:faraday_stabs) { Faraday::Adapter::Test::Stubs.new }

  let(:url) { URI('http://myrpc.local/') }
  let(:faraday_connection) do
    Faraday.new(url: url) do |builder|
      builder.adapter :test, faraday_stabs
    end
  end

  after { faraday_stabs.verify_stubbed_calls }

  it 'has a version number' do
    expect(described_class::VERSION).to eq(
      File.read(File.expand_path('../../VERSION', __dir__)).strip
    )
  end

  it 'inherit Thrift::BaseTransport' do
    expect(described_class.superclass).to eq Thrift::BaseTransport
  end

  describe '#initialize' do
    context 'without arguments' do
      subject(:transport) { described_class.new }

      it { expect { transport }.to raise_error(ArgumentError) }
    end

    context 'with faraday connection' do
      subject(:transport) { described_class.new(faraday_connection) }

      it { expect { transport }.not_to raise_error }

      it 'set faraday_connection' do
        expect(transport.faraday_connection).to eq faraday_connection
      end
    end
  end

  describe '#open?' do
    subject { super().open? }

    it { is_expected.to be true }
  end

  describe '#flush' do
    subject(:flush) { transport.flush }

    let(:transport) { described_class.new(faraday_connection) }

    let(:request_body) { SecureRandom.random_bytes(16) }
    let(:response_body) { SecureRandom.random_bytes(32) }
    let(:headers) { described_class::BASE_HEADERS }

    context 'with transport url not have path' do
      before 'prepare flush' do
        transport.write(request_body)
        faraday_stabs.post('/', request_body, headers) do |_env|
          [200, described_class::BASE_HEADERS, response_body]
        end
      end

      it 'allow read valid response body' do
        flush
        expect(transport.read(response_body.size)).to eq response_body
      end
    end

    context 'with transport url have path' do
      let(:path) { '/custom/prefix' }
      let(:url) { super().merge(path) }

      before 'prepare flush' do
        transport.write(request_body)
        faraday_stabs.post(path, request_body, headers) do |_env|
          [200, described_class::BASE_HEADERS, response_body]
        end
      end

      it 'allow read valid response body' do
        flush
        expect(transport.read(response_body.size)).to eq response_body
      end
    end

    context 'with transport url have invalidpath' do
      let(:path) { '/invalidpath' }
      let(:url) { super().merge(path) }

      before 'prepare flush' do
        transport.write(request_body)
        faraday_stabs.post(path, request_body, headers) do |_env|
          [404, described_class::BASE_HEADERS, 'Not found']
        end
      end

      it 'allow read valid response body' do
        expect { flush }.to raise_error(described_class::UnexpectedHTTPCode,
                                        /404/)
      end
    end

    context 'with faraday raise error' do
      let(:path) { '/invalidpath' }
      let(:url) { super().merge(path) }

      before 'prepare flush' do
        transport.write(request_body)
        faraday_stabs.post(path, request_body, headers) do |_env|
          raise Faraday::ClientError, Exception.new('Custom Faraday error')
        end
      end

      it 'raise wrapped exception' do
        expect { flush }.to raise_error(described_class::FaradayException)
      end
    end

    context 'when flush called not first time' do
      let(:other_request_body) { SecureRandom.random_bytes(20) }
      let(:other_response_body) { SecureRandom.random_bytes(40) }

      before 'first flush' do
        faraday_stabs.post('/', other_request_body, headers) do |_env|
          [200, described_class::BASE_HEADERS, other_response_body]
        end
        transport.write(other_request_body)
        transport.flush
        transport.read(other_response_body.size)
      end

      before 'prepare flush' do
        faraday_stabs.post('/', request_body, headers) do |_env|
          [200, described_class::BASE_HEADERS, response_body]
        end
        transport.write(request_body)
      end

      it 'allow read valid response body' do
        flush
        expect(transport.read(response_body.size)).to eq response_body
      end
    end

    context 'when adapter raise error on prev flush' do
      let(:other_request_body) { SecureRandom.random_bytes(20) }
      let(:other_response_body) { SecureRandom.random_bytes(40) }

      before 'first failed flush' do
        faraday_stabs.post('/', other_request_body, headers) do |_env|
          raise Faraday::ClientError, Exception.new
        end
        transport.write(other_request_body)
        begin
          transport.flush
        rescue described_class::FaradayException
          :ok
        end
      end

      before 'prepare flush' do
        faraday_stabs.post('/', request_body, headers) do |_env|
          [200, described_class::BASE_HEADERS, response_body]
        end
        transport.write(request_body)
      end

      it 'allow read valid response body' do
        flush
        expect(transport.read(response_body.size)).to eq response_body
      end
    end
  end
end
