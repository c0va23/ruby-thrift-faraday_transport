require 'spec_helper'
require 'faraday'

RSpec.describe Thrift::FaradayTransport do
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

      let(:faraday_connection) { Faraday.new }

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
      let(:faraday_connection) { Faraday.new }

      it { expect { transport }.not_to raise_error }

      it 'set faraday_connection' do
        expect(transport.faraday_connection).to eq faraday_connection
      end

      it 'not set path' do
        expect(transport.path).to be path
      end
    end
  end
end
