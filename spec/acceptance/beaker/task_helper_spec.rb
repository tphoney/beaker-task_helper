require 'spec_helper_acceptance'

describe Beaker::I18nHelper do
  context 'japanese' do
    describe '#install_language_pack_on' do
      it 'installs a language pack' do
        install_language_on(hosts, 'ja_JP.utf-8')
        output = shell('localectl list-locales').stdout

        expect(output).to match %r{ja_JP}
      end

      it 'changes the locale to japanese' do
        change_locale_on(hosts, 'ja_JP.utf-8')
        content = shell('locale').stdout

        expect(content).to match(%r{ja_JP})
      end

      it 'changes the locale back to english' do
        change_locale_on(hosts, 'en_US.utf-8')
        content = shell('locale').stdout

        expect(content).to match %r{en_US}
        expect(content).to_not match(%r{ja_JP})
      end

      it 'errors given a bad lang string' do
        expect { change_locale_on(hosts, 'jaJP') }.to raise_error(RuntimeError)
      end
    end
  end
end
