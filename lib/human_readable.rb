# frozen_string_literal: true

# Copyright 2020 Mack Earnhardt

require 'human_readable/version'
require 'ostruct'
require 'securerandom'

# Human readable random tokens with limited ambiguous characters
module HumanReadable
  # +#generate+ output_size must be >= 2 due to check character
  class MinSizeTwo < StandardError; end

  class << self
    # Yields block for configuration
    #
    #   HumanReadable.configure do |c|
    #     c.substitution_hash[:B] = 8
    #     c.substitution_hash[:U] = nil
    #     c.substitution_hash['$'] = '$'
    #     # or equivalently
    #     c.substitution_hash = { I: 1, L: 1, O: 0, U: nil, B: 8, '$' => '$'}
    #   end
    #
    # Specified keys won't be used during generation, and values will be substituted during
    # validation, increasing the likelihood that a misread character can be restored. Extend
    # or replace the substitutions to alter the character set. For convenience, digits
    # and symbols are allowed in the hash and are translated to characters during usage.
    #
    # DEFAULT:
    #   substitution_hash: { I: 1, L: 1, O: 0, U: :V }
    #
    # @note Changing substitution_hash keys alters the check character, invalidating previous tokens.
    # @return [Hash] resulting substitution hash
    def configure
      yield(configuration)
      configuration.substitution_hash
    end

    # Generates a random token of the requested size
    #
    # @note Minimum size is 2 since the last character is a check character
    # @return [String] random token with check character
    def generate(output_size: 10)
      raise(MinSizeTwo) if output_size < 2

      (token = generate_random(output_size - 1)) + check_character(token)
    end

    # Clean and validate a candidate token
    #
    # * Upcases
    # * Applies substitutions
    # * Remove characters not in available character set
    # * Validates the check character
    #
    # @param input [String] the candidate token
    # @return [String] possibly modified token if valid
    # @return [nil] if the token isn't valid
    def valid_token?(input)
      return unless input.is_a?(String)

      codepoints = input.upcase.tr(trans_from, trans_to).chars.map! { |c| charset.index(c) }
      codepoints.compact!

      return if codepoints.size < 2

      array =
        codepoints.reverse.each_with_index.map do |codepoint, i|
          codepoint *= 2 if i.odd?
          codepoint / charset_size + codepoint % charset_size
        end

      codepoints.map { |codepoint| charset[codepoint] }.join if (array.sum % charset_size).zero?
    end

    # Characters available for token generation
    #
    # Manipulate by configuring +substitution_hash+
    #
    # DEFAULT: Digits 0-9 and uppercase letters A-Z except for ILOU
    # @return [Array] of available characters
    def charset
      @charset ||=
        begin
          array = (('0'..'9').to_a + ('A'..'Z').to_a - trans_from.chars + trans_to.chars - nil_substitutions)
          array.uniq!
          array.sort!
        end
    end

    # Reset configuration and memoizations
    #
    # @return [Array] list of variables reset
    def reset
      instance_variables.each { |sym| remove_instance_variable(sym) }
    end

  private

    def configuration
      @configuration ||= OpenStruct.new(
        substitution_hash: { I: 1, L: 1, O: 0, U: :V }
      )
    end

    # Generates a random string of the requested length from the charset
    #
    # We could use one of the below routines in +#generate+, but the first
    # increases the chances of token collisions and the second is too slow.
    #
    #   Array.new(random_size) { charset.sample }
    #   # or
    #   Array.new(random_size) { charset.sample(random: SecureRandom) }
    #
    # Instead we attempt to optimize the number of bytes generated with each
    # call to SecureRandom.
    def generate_random(random_size)
      return '' unless random_size.positive?

      codepoints = []

      while codepoints.size < random_size
        bytes_needed = ((random_size - codepoints.size) * byte_multiplier).ceil

        codepoints +=
          begin
            array =
              SecureRandom
              .random_bytes(bytes_needed)
              .unpack1('B*')
              .scan(scan_regexp)
              .map! { |bin_string| bin_string.to_i(2) }
            array.select { |codepoint| codepoint < charset_size }
          end
      end

      codepoints[0, random_size].map { |codepoint| charset[codepoint] }.join
    end

    # Compute check character using Luhn mod N algorithm
    #
    # *CAUTION:* Changing substitution_hash keys alters the output
    def check_character(input)
      array =
        input.chars.reverse.each_with_index.map do |c, i|
          d = charset.index(c)
          d *= 2 if i.even?
          d / charset_size + d % charset_size
        end

      mod = (charset_size - array.sum % charset_size) % charset_size

      charset[mod]
    end

    def char_bits
      @char_bits ||= (charset_size - 1).to_s(2).size
    end

    def scan_regexp
      @scan_regexp ||= /.{#{char_bits}}/
    end

    def byte_multiplier
      @byte_multiplier ||=
        begin
          bit_multiplier = char_bits / 8.0
          # Then extra 1.1 helps performance due to randomness of misses
          miss_percentage = 2**char_bits * 1.0 / charset_size * 1.1
          bit_multiplier * miss_percentage
        end
    end

    def charset_size
      @charset_size ||= charset.size
    end

    def nil_substitutions
      @nil_substitutions ||=
        begin
          array = configuration.substitution_hash.each.map { |k, v| k if v.nil? }
          array.compact!
          array.map!(&:to_s)
          array.map!(&:upcase)
        end
    end

    def trans_from
      @trans_from ||=
        begin
          array = configuration.substitution_hash.each.map { |k, v| k unless v.nil? }
          array.compact!
          array.map!(&:to_s)
          array.map!(&:upcase)
          array.join
        end
    end

    def trans_to
      @trans_to ||=
        begin
          array = configuration.substitution_hash.values
          array.compact!
          array.map!(&:to_s)
          array.map!(&:upcase)
          array.join
        end
    end
  end
end
