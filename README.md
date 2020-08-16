[![Gem Version](https://badge.fury.io/rb/human_readable.svg)](https://badge.fury.io/rb/human_readable)

# HumanReadable

Human readable random tokens with limited ambiguous characters.

Focus is readability in poor conditions or from potentially damaged printed documents rather than cryptographic uses.
Despite this focus, SecureRandom is used to help avoid collisions.

Inspired by Douglas Crockford's [Base 32](https://www.crockford.com/base32.html), but attempts to correct mistakes by substituting the most likely misread.
To make substitution safer, the token includes a check character generated using the [Luhn mod N algorithm](https://en.wikipedia.org/wiki/Luhn_mod_N_algorithm).
Default character set is all caps based on this published study on [text legibility](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2016788/), which matches Crockford as well.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'human_readable'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install human_readable

## Usage

For 10 characters of the default character set, use `HumanReadable.generate`.
For other lengths (2..x), use `HumanReadable.generate(output_size: 50)`.

## Configuration

* Change available characters and substitution by manipulating `substitution_hash`
* To include non-default characters, add a self-reference to the hash
* Inspect available characters using `HumanReadable.charset`
* For convenience, numbers and symbols are allowed in the hash and are translated to characters during usage

**CAUTION:** Changing `substitution_hash` keys alters the check character, invalidating previous tokens.


    HumanReadable.configure do |c|
      # Default: substitution_hash = { I: 1, L: 1, O: 0, U: :V }

      # Modifications
      c.substitution_hash[:B] = 8
      c.substitution_hash[:U] = nil
      # or equivalently
      c.substitution_hash = { I: 1, L: 1, O: 0, U: nil, B: 8}

      # Extend charset
      c.extend_chars << %w[~ ! @ $]
    end

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/MacksMind/human_readable>.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
