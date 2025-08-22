require 'spec_helper'

describe ConstConf::JSONPlugin do
  let(:json_file) { asset('config.json') }

  describe '#json' do
    context 'when file exists' do
      it 'reads and parses JSON content as a hash' do
        instance = double('Config').extend(described_class)
        result = instance.json(json_file)
        expect(result.hello).to eq 'world'
      end

      it 'handles JSON with custom object_class' do
        instance = double('Config').extend(described_class)
        foobar_class = Class.new(JSON::GenericObject)
        result = instance.json(json_file, object_class: foobar_class)
        expect(result).to be_a(foobar_class)
      end
    end

    context 'when file does not exist' do
      let(:nonexistent_file) { asset('nonexistent.json') }

      it 'returns nil when file does not exist and required is false' do
        instance = double('Config').extend(described_class)
        result = instance.json(nonexistent_file, required: false)
        expect(result).to be_nil
      end

      it 'raises RequiredValueNotConfigured when file is required and does not exist' do
        instance = double('Config').extend(described_class)
        expect {
          instance.json(nonexistent_file, required: true)
        }.to raise_error(ConstConf::RequiredValueNotConfigured)
      end
    end

    context 'with custom configuration module' do
      before do
        eval %{
          if Object.const_defined?(:ConstConfTestModuleWithJSON)
            Object.send(:remove_const, :ConstConfTestModuleWithJSON)
          end
          module ::ConstConfTestModuleWithJSON
            include ConstConf
            plugin ConstConf::JSONPlugin

            description 'Module with JSONPlugin'

            CONFIG_VALUE = set do
              description 'Configuration from JSON file'
              default json("#{json_file}")
            end
          end
        }
      end

      it 'can be used in a ConstConf module' do
        expect(ConstConfTestModuleWithJSON::CONFIG_VALUE.hello).to eq 'world'
      end
    end
  end
end
