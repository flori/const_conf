require 'spec_helper'

describe ConstConf::YAMLPlugin do
  let(:yaml_file) { asset('config.yml') }
  let(:env_yaml_file) { asset('config_env.yml') }

  describe '#yaml' do
    context 'when file exists' do
      it 'reads and parses YAML content as a hash' do
        instance = double('Config').extend(described_class)
        result = instance.yaml(yaml_file)
        expect(result.hello).to eq 'world'
      end

      it 'handles environment-specific loading when env: true' do
        instance = double('Config').extend(described_class)
        ENV['RAILS_ENV'] = 'development'

        # This will actually call complex_config_with_env with the real ENV value
        result = instance.yaml(env_yaml_file, env: true)
        expect(result.hello).to eq 'world'
      end

      it 'handles environment-specific loading with explicit env' do
        instance = double('Config').extend(described_class)
        result = instance.yaml(env_yaml_file, env: 'production')
        expect(result.hello).to eq 'outer world'
      end
    end

    context 'when file does not exist' do
      let(:nonexistent_file) { asset('nonexistent.yml') }

      it 'returns nil when file does not exist and required is false' do
        instance = double('Config').extend(described_class)
        result = instance.yaml(nonexistent_file, required: false)
        expect(result).to be_nil
      end

      it 'raises RequiredValueNotConfigured when file is required and does not exist' do
        instance = double('Config').extend(described_class)
        expect {
          instance.yaml(nonexistent_file, required: true)
        }.to raise_error(ConstConf::RequiredValueNotConfigured)
      end
    end

    context 'when env is specified but no RAILS_ENV is set' do
      it 'raises RequiredValueNotConfigured when env is true and RAILS_ENV is not set' do
        instance = double('Config').extend(described_class)
        ENV['RAILS_ENV'] = nil

        expect {
          instance.yaml(env_yaml_file, env: true)
        }.to raise_error(ConstConf::RequiredValueNotConfigured)
      end
    end

    context 'with custom configuration module' do
      before do
        eval %{
          if Object.const_defined?(:ConstConfTestModuleWithYAML)
            Object.send(:remove_const, :ConstConfTestModuleWithYAML)
          end
          module ::ConstConfTestModuleWithYAML
            include ConstConf
            plugin ConstConf::YAMLPlugin

            description 'Module with YAMLPlugin'

            CONFIG_VALUE = set do
              description 'Configuration from YAML file'
              default yaml("#{yaml_file}")
            end
          end
        }
      end

      it 'can be used in a ConstConf module' do
        expect(ConstConfTestModuleWithYAML::CONFIG_VALUE.hello).to eq 'world'
      end
    end
  end
end
