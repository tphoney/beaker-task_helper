require 'spec_helper'

RSpec.describe Beaker::I18nHelper do # rubocop:disable Metrics/BlockLength
  it 'has a version number' do
    expect(Beaker::I18nHelper::VERSION).not_to be nil
  end
  describe '#validate_lang_string' do
    context 'with invalid args' do
      ['jaJP', 'ja_JP-utf8', 'foo', '123'].each do |lang|
        it_behaves_like 'an invalid lang string', lang
      end
    end
    context 'with valid args' do
      ['ja_JP', 'ja-JP', 'ja_JP.utf-8', 'ja-JP.UTF-8'].each do |lang|
        it_behaves_like 'a valid lang string', lang
      end
    end
  end
  describe '#parse_lang' do
    context 'underscored locale string' do
      let(:val) { parse_lang('ja_JP.utf8') }
      it 'returns an array' do
        expect(val).to be_kind_of(Array)
      end
      it 'returns correct information' do
        expect(val).to eq(%w[ja JP])
      end
    end
    context 'hyphenated locale string' do
      let(:val) { parse_lang('ja-JP.utf8') }
      it 'returns an array' do
        expect(val).to be_kind_of(Array)
      end
      it 'returns correct information' do
        expect(val).to eq(%w[ja JP])
      end
    end
  end
end
