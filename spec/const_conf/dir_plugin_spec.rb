require 'spec_helper'

describe ConstConf::DirPlugin, protect_env: true do
  let(:temp_dir) { Dir.mktmpdir }
  let(:config_dir) { File.join(temp_dir, 'myapp') }
  let(:file_in_dir) { File.join(config_dir, 'config.yaml') }
  let(:nonexistent_file) { File.join(config_dir, 'nonexistent.txt') }

  before do
    # Create a test config directory and file
    FileUtils.mkdir_p(config_dir)
    File.write(file_in_dir, "key: value\nother_key: other_value\n")
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe ConstConf::DirPlugin::ConfigDir do
    let(:config_dir_instance) do
      described_class.new('myapp', root_path: temp_dir, env_var: nil, env_var_name: nil)
    end

    describe '#initialize' do
      it 'initializes with name and root path' do
        expect(config_dir_instance).to be_a(described_class)
      end

      it 'raises ArgumentError when both env_var and env_var_name are provided' do
        expect {
          described_class.new('myapp', root_path: temp_dir, env_var: 'value', env_var_name: 'VAR_NAME')
        }.to raise_error(ArgumentError)
      end

      it 'uses env_var_name to lookup environment variable value' do
        ENV['CUSTOM_HOME'] = temp_dir
        config_dir_with_env = described_class.new('myapp', env_var: nil, env_var_name: 'CUSTOM_HOME')
        expect(config_dir_with_env.to_s).to include(temp_dir)
      end
    end

    describe '#to_s' do
      it 'returns the directory path as string' do
        result = config_dir_instance.to_s
        expect(result).to include('myapp')
      end
    end

    describe '#join' do
      it 'joins path with directory path' do
        joined_path = config_dir_instance.join('config.yaml')
        expect(joined_path.to_s).to eq file_in_dir
      end
    end

    describe '#read' do
      context 'when file exists' do
        it 'reads file content as string' do
          result = config_dir_instance.read('config.yaml')
          expect(result).to eq "key: value\nother_key: other_value\n"
        end

        it 'handles file with block' do
          result = config_dir_instance.read('config.yaml') do |file|
            file.read
          end
          expect(result).to eq "key: value\nother_key: other_value\n"
        end
      end

      context 'when file does not exist' do
        it 'returns nil when file does not exist and no default or required' do
          result = config_dir_instance.read('nonexistent.txt')
          expect(result).to be_nil
        end

        it 'returns default value when file does not exist but default is provided' do
          result = config_dir_instance.read('nonexistent.txt', default: 'default_content')
          expect(result).to eq 'default_content'
        end

        it 'raises RequiredValueNotConfigured when file required and does not exist' do
          expect {
            config_dir_instance.read('nonexistent.txt', required: true)
          }.to raise_error(ConstConf::RequiredValueNotConfigured)
        end

        it 'yields StringIO with default when block given and file does not exist' do
          result = config_dir_instance.read('nonexistent.txt', default: 'default_content') do |io|
            io.read
          end
          expect(result).to eq 'default_content'
        end
      end
    end

    describe '#derive_directory_path' do
      it 'combines root path and name' do
        path = config_dir_instance.send(:derive_directory_path, 'myapp', temp_dir)
        expect(path.to_s).to include('myapp')
      end
    end

    describe '#default_root_path' do
      it 'returns default XDG config path from HOME' do
        ENV['HOME'] = temp_dir
        path = config_dir_instance.send(:default_root_path)
        expect(path.to_s).to include('.config')
      end
    end
  end

  describe '#dir' do
    let(:instance) { double('Config').extend(described_class) }

    context 'with existing file in directory' do
      it 'reads file content from directory' do
        result = instance.dir('myapp', 'config.yaml', env_var: temp_dir)
        expect(result).to eq "key: value\nother_key: other_value\n"
      end
    end

    context 'with non-existent file' do
      it 'returns default when provided' do
        result = instance.dir('myapp', 'nonexistent.txt', env_var: temp_dir, default: 'default_value')
        expect(result).to eq 'default_value'
      end

      it 'returns nil when no default and file does not exist' do
        result = instance.dir('myapp', 'nonexistent.txt', env_var: temp_dir)
        expect(result).to be_nil
      end

      it 'raises error when required is true and file does not exist' do
        expect {
          instance.dir('myapp', 'nonexistent.txt', env_var: temp_dir, required: true)
        }.to raise_error(ConstConf::RequiredValueNotConfigured)
      end
    end
  end

  describe 'integration with ConstConf settings' do
    let(:module_with_dir_plugin) do
      Module.new do
        include ConstConf
        plugin ConstConf::DirPlugin

        description 'Module with DirPlugin'

        # Test basic dir usage
        CONFIG_FILE = set do
          description 'Configuration from directory file'
          default dir('myapp', 'config.yaml', env_var: temp_dir)
          decode { |s| YAML.load(s) }
        end

        # Test required directory file
        REQUIRED_DIR_FILE = set do
          description 'Required file in directory'
          default dir('myapp', 'nonexistent.txt', env_var: temp_dir, required: false)
        end
      end
    end

    before do
      # Create the module with dynamic eval to simulate real usage
      eval <<~RUBY
        if Object.const_defined?(:ConstConfTestModuleWithDir)
          Object.send(:remove_const, :ConstConfTestModuleWithDir)
        end
        module ConstConfTestModuleWithDir
          include ConstConf
          plugin ConstConf::DirPlugin

          description 'Module with DirPlugin'

          CONFIG_FILE = set do
            description 'Configuration from directory file'
            default dir('myapp', 'config.yaml', env_var: '#{temp_dir}')
            decode { |s| YAML.load(s) }
          end
        end
      RUBY
    end

    it 'can read files from directories' do
      # This will test the actual integration
      expect(ConstConfTestModuleWithDir::CONFIG_FILE).to be_a(Hash)
    end

    context 'XDG-compliant directory structure' do
      before do
        eval <<~RUBY
          if Object.const_defined?(:ConstConfXDGModule)
            Object.send(:remove_const, :ConstConfXDGModule)
          end
          module ConstConfXDGModule
            include ConstConf
            plugin ConstConf::DirPlugin

            description 'XDG Compliant Module'

            XDG_CONFIG_HOME = set do
              description 'XDG Config HOME'
              prefix ''
            end

            API_KEY = set do
              description 'API Key from XDG config'
              default dir('myapp', 'api_key.txt', env_var: ConstConfXDGModule::XDG_CONFIG_HOME)
            end
          end
        RUBY
      end

      it 'handles XDG-compliant directory structure' do
        # This tests the XDG pattern from the example
        expect { ConstConfXDGModule::API_KEY }.not_to raise_error
      end
    end
  end

  describe 'error handling' do
    let(:instance) { double('Config').extend(described_class) }

    it 'handles directory operations gracefully' do
      # Test that we can handle edge cases in directory operations
      expect {
        instance.dir('nonexistent', 'file.txt', env_var: '/nonexistent/path')
      }.not_to raise_error
    end
  end

  describe 'complex scenarios' do
    let(:nested_config_dir) { File.join(temp_dir, 'app', 'config') }
    let(:nested_file) { File.join(nested_config_dir, 'settings.yml') }

    before do
      FileUtils.mkdir_p(nested_config_dir)
      File.write(nested_file, "nested: true\n")
    end

    it 'works with nested directory structures' do
      instance = described_class::ConfigDir.new('app/config', root_path: temp_dir, env_var: nil, env_var_name: nil)
      result = instance.read('settings.yml')
      expect(result).to eq "nested: true\n"
    end
  end
end
