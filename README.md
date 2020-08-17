[![Gem Version](https://badge.fury.io/rb/human_readable.svg)](https://badge.fury.io/rb/human_readable)

# HumanReadable

Human readable random tokens without ambiguous characters, and optional Emoji support.

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
For other lengths (2..x), use `HumanReadable.generate(output_size: 50)`, or change `output_size` in the configuration.

## Configuration

* Add or change substitutions by configuring `substitution_hash`
* To include non-default characters without substitution, configure `extend_chars`
* To exclude default characters, configure `exclude_chars`
* Inspect available characters using `HumanReadable.charset`
* For convenience, numbers and symbols are allowed in `substitution_hash` and are translated to characters during usage

**CAUTION:** Changing available characters alters the check character, invalidating previous tokens.


    HumanReadable.configure do |c|
      c.substitution_hash = { %w[I L] => 1, O: 0, U: :V } # Default
      c.output_size = 10                                  # Default

      # Add or change substitutions
      c.substitution_hash[:B] = 8
      c.substitution_hash[:U] = nil
      # or equivalently
      c.substitution_hash = { %w[I L] => 1, O: 0, U: nil, B: 8}

      # Extend charset when no substitution is needed
      c.extend_chars << %w[~ ! @ $]

      # Exclude from charset
      c.exclude_chars = %w[X Y Z]

      # Supports Emoji!!
      c.extend_chars << %w[⛰️ 🧻 ✂️ 🦎 🖖]
      c.substitution_hash['🖤'] = '❤️'

      # And understands skin tones
      c.remove_skin_tones = false                         # Default
      c.substitution_hash[%w[👍🏻 👍🏼 👍🏽 👍🏾 👍🏿]] = '👍'
      # -or-
      c.remove_skin_tones = true
      c.extend_chars << '👍'
    end

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/MacksMind/human_readable>.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
