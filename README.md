# Thrift::FaradayTransport

[![Build Status](https://travis-ci.org/c0va23/ruby-thrift-faraday_transport.svg?branch=feature%2Fconfigure-travis)](https://travis-ci.org/c0va23/ruby-thrift-faraday_transport)
[![Inline docs](http://inch-ci.org/github/c0va23/ruby-thrift-faraday_transport.svg?branch=master)](http://inch-ci.org/github/c0va23/ruby-thrift-faraday_transport)

Ruby GEM implemented [Thrift](https://github.com/apache/thrift/tree/master/lib/rb)
HTTP transport basen on [Faraday](https://github.com/lostisland/faraday).

It GEM allow use any HTTP-adapter supported by Faraday as HTTP-transport for
Thrift. See [Usage](#Usage) for examples.

## Documentation

http://www.rubydoc.info/github/c0va23/ruby-thrift-faraday_transport/

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'thrift-faraday_transport'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install thrift-faraday_transport

## Usage

```ruby
require 'uri'
require 'net/http/persistent'

url = URI('http://mytriftserver:12345/endpoint')

faraday_connection = Faraday.new(url: url) do |f|
  f.adapter :net_http_persistent
end
transport = ::Thrift::FaradayTransport.new(faraday_connection)
protocol = ::Thrift::BinaryProtocol.new(transport)
transport.open
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake` to run the tests and rubcop linter. You can also run `bin/console`
for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `VERSION`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/c0va23/thrift-faraday_transport.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
