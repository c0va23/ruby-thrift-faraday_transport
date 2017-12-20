require 'spec_helper'
require 'securerandom'

RSpec.describe Thrift::FaradayTransport do
  subject { described_class.new(faraday_connection) }

  let(:faraday_stabs) { Faraday::Adapter::Test::Stubs.new }

  let(:faraday_connection) do
    Faraday.new do |builder|
      builder.adapter :test, faraday_stabs
    end
  end

  after { faraday_stabs.verify_stubbed_calls }

  it 'has a version number' do
    expect(described_class::VERSION).to eq(
      File.read(File.expand_path('../../VERSION', __dir__))
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

      it 'not set path' do
        expect(transport.path).to be nil
      end
    end

    context 'with faraday_connection and path' do
      subject(:transport) do
        described_class.new(faraday_connection, path: path)
      end

      let(:path) { 'custom prefix' }

      it { expect { transport }.not_to raise_error }

      it 'set faraday_connection' do
        expect(transport.faraday_connection).to eq faraday_connection
      end

      it 'not set path' do
        expect(transport.path).to be path
      end
    end
  end

  describe '#open?' do
    subject { super().open? }

    it { is_expected.to be true }
  end

  describe '#flush' do
    let(:request_body) { SecureRandom.random_bytes(16) }
    let(:response_body) { SecureRandom.random_bytes(32) }
    let(:headers) { described_class::BASE_HEADERS }

    context 'with transport not have path' do
      subject(:flush) { transport.flush }

      let(:transport) { described_class.new(faraday_connection) }

      before do
        transport.write(request_body)
        faraday_stabs.post('/', request_body, headers) do |_env|
          [200, described_class::BASE_HEADERS, response_body]
        end
      end

      it 'call post thrift data via adapter' do
        flush
        expect(transport.read(response_body.size)).to eq response_body
      end
    end
  end
end
