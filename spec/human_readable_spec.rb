# frozen_string_literal: true

# Copyright 2020 Mack Earnhardt

RSpec.describe HumanReadable do
  before do
    described_class.reset
  end

  it 'has a version number' do
    expect(HumanReadable::VERSION).not_to be(nil)
  end

  describe '#charset' do
    context 'with non-default chars in extend_chars' do
      let(:extensions) { %w[~ @ # $] }

      before do
        described_class.configure do |c|
          c.extend_chars << extensions
        end
      end

      it 'extends the charset' do
        expect(described_class.charset & extensions).to match_array(extensions)
      end
    end

    context 'with default chars in exclude_chars' do
      let(:exclusions) { %w[X Y Z] }

      before do
        described_class.configure do |c|
          c.exclude_chars << exclusions
        end
      end

      it 'extends the charset' do
        expect(described_class.charset & exclusions).to eq([])
      end
    end
  end

  describe '#generate' do
    subject(:output) { described_class.generate }

    it 'generates a 10 digit token by default' do
      expect(output.size).to eq(10)
    end

    it 'generates others sizes by request' do
      (4..20).each { |i| expect(described_class.generate(output_size: i).size).to eq(i) }
    end

    it 'generates valid tokens' do
      [2, 3, 5, 8].each do |i|
        token = described_class.generate(output_size: i)
        expect(described_class.valid_token?(token)).to eq(token)
      end
    end

    it 'has minimum token size' do
      expect { described_class.generate(output_size: 1) }.to(
        raise_exception(described_class::MinSizeTwo)
      )
    end

    it 'uses the specified characters' do
      expect(output).to match(/^[#{described_class.charset.join}]+$/)
    end

    context 'with empty substitution_hash' do
      before do
        described_class.configure do |c|
          c.substitution_hash = {}
        end
      end

      it 'uses the whole charset' do
        token = described_class.generate(output_size: 1000)
        expect(token).to include(described_class.charset.last)
      end
    end

    context 'with non-default chars in substitution_hash' do
      before do
        described_class.configure do |c|
          c.substitution_hash['$'] = '$'
        end
      end

      it 'uses the whole charset' do
        token = described_class.generate(output_size: 1000)
        expect(token).to include('$')
      end
    end
  end

  describe '#valid_token?' do
    subject { input.map { |token| described_class.valid_token?(token) } }

    let(:valid_tokens) do
      (2..12).map { |n| described_class.generate(output_size: n) }
    end

    let(:input) { valid_tokens }

    it { is_expected.to eq(valid_tokens) }

    context 'with embedded cruft' do
      let(:input) do
        cruft = %w[! @ # $ -]
        valid_tokens.map { |token| token.dup.insert(rand(token.size), cruft.sample) }
      end

      it { is_expected.to eq(valid_tokens) }
    end

    context 'with lowercase' do
      let(:input) { valid_tokens.map(&:downcase) }

      it { is_expected.to eq(valid_tokens) }
    end

    context 'with blank-ish input' do
      let(:input) { [nil, '', ' ', "  \n"] }

      it { is_expected.to eq(Array.new(input.size, nil)) }
    end

    context 'with accidental substitutions' do
      # rubocop:disable Style/StringHashKeys
      # Need character keys for the reverse substitution to work
      let(:reverse_substitution_hash) { { '1' => %w[I L], '0' => ['O'], 'V' => ['U'] } }
      # rubocop:enable Style/StringHashKeys

      let(:input) do
        valid_tokens.map do |token|
          array =
            token.chars.map do |c|
              reverse_substitution_hash[c]&.sample || c
            end
          array.join
        end
      end

      it { is_expected.to eq(valid_tokens) }
    end

    context 'when invalid' do
      let(:input) do
        valid_tokens.map do |token|
          str = token.dup
          str[rand(str.size)] = described_class.charset.sample while str == token
          str
        end
      end

      it { is_expected.to eq(Array.new(input.size)) }
    end

    context 'with explicit nil substitutions' do
      let(:input) do
        valid_tokens.map do |token|
          # Insert B or b
          "#{token[0..1]}#{%w[B b].sample}#{token[2..-1]}"
        end
      end

      before do
        described_class.configure do |c|
          c.substitution_hash[:b] = nil
        end
      end

      it { is_expected.to eq(valid_tokens) }
    end

    context 'with digits only' do
      before do
        described_class.configure do |c|
          c.substitution_hash = Hash[('A'..'Z').map { |digit| [digit, nil] }]
        end
      end

      it 'has a numeric charset' do
        expect(described_class.charset).to eq(('0'..'9').to_a)
      end

      {
        Visa: '4242424242424242',
        MasterCard: '5555555555554444',
        AmericanExpress: '378282246310005',
        Discover: '6011111111111117'
      }.each do |brand, number|
        context "validates #{brand}" do
          let(:input) { [number] }

          it { is_expected.to eq([number]) }
        end
      end
    end
  end

  describe 'Emoji support' do
    subject { input.map { |token| described_class.valid_token?(token) } }

    let(:valid_tokens) { Array.new(100) { described_class.generate } }

    let(:thumbs_up_skin_tones) { %w[👍 👍🏻 👍🏼 👍🏽 👍🏾 👍🏿] }

    before do
      described_class.configure do |c|
        c.remove_skin_tones = true
      end
    end

    context 'with rock paper scissors lizard spock' do
      subject(:token) { described_class.generate(output_size: 1000) }

      let(:extensions_with_skin_tone) { %w[⛰️ 🧻 ✂️ 🦎 🖖🏻] }
      let(:extensions) { %w[⛰️ 🧻 ✂️ 🦎 🖖] }

      before do
        described_class.configure do |c|
          c.extend_chars << extensions_with_skin_tone
        end
      end

      it 'extends the charset' do
        expect(described_class.charset & extensions).to match_array(extensions)
      end

      it 'uses the whole charset' do
        expect(token.each_grapheme_cluster.to_a & extensions).to match_array(extensions)
      end

      it 'generates a valid token' do
        expect(described_class.valid_token?(token)).to eq(token)
      end
    end

    context 'with black hearts to red' do
      let(:input) do
        valid_tokens.map do |token|
          array =
            token.each_grapheme_cluster.map do |c|
              c == '❤️' ? '🖤' : c
            end
          array.join
        end
      end

      before do
        described_class.configure do |c|
          c.substitution_hash['🖤'] = '❤️'
        end
      end

      it { is_expected.to eq(valid_tokens) }
    end

    context 'with removed skin tones' do
      let(:input) do
        valid_tokens.map do |token|
          array =
            token.each_grapheme_cluster.map do |c|
              c == '👍🏿' ? thumbs_up_skin_tones.sample : c
            end
          array.join
        end
      end

      before do
        described_class.configure do |c|
          c.substitution_hash[thumbs_up_skin_tones] = '👍🏿'
          c.extend_chars << thumbs_up_skin_tones.first
        end
      end

      it { is_expected.to eq(valid_tokens) }
    end

    context 'with thumbs up for all the people' do
      let(:input) do
        valid_tokens.map do |token|
          array =
            token.each_grapheme_cluster.map do |c|
              c == '👍🏿' ? thumbs_up_skin_tones.sample : c
            end
          array.join
        end
      end

      before do
        described_class.configure do |c|
          c.substitution_hash[thumbs_up_skin_tones] = '👍🏿'
          c.extend_chars << thumbs_up_skin_tones.first
          c.remove_skin_tones = false
        end
      end

      it { is_expected.to eq(valid_tokens) }
    end
  end
end
