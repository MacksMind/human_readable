# frozen_string_literal: true

# Copyright 2020 Mack Earnhardt

RSpec.describe HumanReadable do
  it 'has a version number' do
    expect(HumanReadable::VERSION).not_to be(nil)
  end

  describe '#generate' do
    subject(:output) { described_class.generate }

    before do
      described_class.reset
    end

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

    before do
      described_class.reset
    end

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
      let(:trans_hash) do
        h = {}
        (0..described_class.__send__(:trans_to).size - 1).each do |i|
          trans_to = described_class.__send__(:trans_to)[i].chars
          h[trans_to] ||= []
          h[trans_to] << described_class.__send__(:trans_from)[i].chars
        end

        h
      end

      let(:input) do
        valid_tokens.map do |token|
          array =
            token.chars.each do |c|
              trans_hash[c]&.sample || c
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
  end
end
