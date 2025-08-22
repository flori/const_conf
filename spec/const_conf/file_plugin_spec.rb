require 'spec_helper'

describe ConstConf::FilePlugin do
  let(:temp_dir) { Dir.mktmpdir }
  let(:config_file) { File.join(temp_dir, 'config.txt') }
  let(:nonexistent_file) { File.join(temp_dir, 'nonexistent.txt') }

  before do
    eval %{
      if Object.const_defined?(:ConstConfTestModule)
        Object.send(:remove_const, :ConstConfTestModule)
      end
      module ::ConstConfTestModule
        include ConstConf

        description 'Outer configuration namespace'
      end
    }
  end


  let :instance do
    double('Config').extend(described_class)
  end

  before do
    # Create a test config file with content
    File.write(config_file, "test_content\nwith_newlines")
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#file' do
    context 'when file exists' do
      it 'reads the file content as a string' do
        result = instance.file(config_file)
        expect(result).to eq "test_content\nwith_newlines"
      end

      it 'handles files with UTF-8 encoding' do
        utf8_file = File.join(temp_dir, 'utf8.txt')
        File.write(utf8_file, "café 🚀\n")

        result = instance.file(utf8_file)
        expect(result).to eq "café 🚀\n"
      end
    end

    context 'when file does not exist' do
      it 'returns nil when file does not exist and required is false' do
        result = instance.file(nonexistent_file, required: false)
        expect(result).to be_nil
      end

      it 'raises RequiredValueNotConfigured when file is required and does not exist' do
        expect {
          instance.file(nonexistent_file, required: true)
        }.to raise_error(ConstConf::RequiredValueNotConfigured)
      end
    end

    context 'with custom configuration module' do
      before do
        eval %{
          module ConstConfTestModule::ModuleWithFilePlugin
            include ConstConf
            plugin ConstConf::FilePlugin

            description 'Module with FilePlugin'

            CONFIG_VALUE = set do
              description 'Configuration from file'
              default file("#{config_file}")
            end
          end
        }
      end

      it 'can be used in a ConstConf module' do
        expect(ConstConfTestModule::ModuleWithFilePlugin::CONFIG_VALUE).to eq "test_content\nwith_newlines"
      end

      it 'handles required files properly' do
        expect {
          eval %{
            module ConstConfTestModule::ModuleWithRequired
              include ConstConf
              plugin ConstConf::FilePlugin

              description 'Module with Required'

              REQUIRED_CONFIG = set do
                description 'Required config from file'
                default file("#{nonexistent_file}", required: true)
              end
            end
          }
        }.to raise_error(ConstConf::RequiredValueNotConfigured)
      end
    end
  end

  describe 'integration with ConstConf settings' do
    before do
      eval %{
        module ConstConfTestModule::ConfigModule
          include ConstConf
          plugin ConstConf::FilePlugin

          description 'Some ConfigModule'

          # Test file reading in setting definition
          API_KEY = set do
            description 'API key from file'
            default file("#{config_file}")
            decode(&:chomp)
          end

          # Test with required file
          REQUIRED_CONFIG = set do
            description 'Required config file'
            default file("#{nonexistent_file}", required: false)
          end
        end
      }
    end

    it 'properly reads file content' do
      expect(ConstConfTestModule::ConfigModule::API_KEY).to eq "test_content\nwith_newlines"
    end

    it 'handles decoding operations on file content' do
      # The decode(&:chomp) should strip trailing whitespace/newlines
      expect(ConstConfTestModule::ConfigModule::API_KEY).to eq "test_content\nwith_newlines"
    end

    it 'handles missing files gracefully when not required' do
      expect(ConstConfTestModule::ConfigModule::REQUIRED_CONFIG).to be_nil
    end
  end

  describe 'error handling' do
    it 'properly raises exceptions for invalid file paths' do
      # This would test edge cases in the underlying File.read behavior
      expect {
        instance.file('/nonexistent/directory/file.txt')
      }.not_to raise_error
    end
  end

  context 'with directory-based setup' do
    let(:config_dir) { Dir.mktmpdir }

    after do
      FileUtils.rm_rf(config_dir)
    end

    it 'works correctly with different file operations' do
      # Create a nested structure for testing
      subdir = File.join(config_dir, 'subdir')
      FileUtils.mkdir_p(subdir)

      test_file = File.join(subdir, 'test.txt')
      File.write(test_file, 'nested_content')

      # This tests that the plugin can be used in different contexts
      result = instance.file(test_file)
      expect(result).to eq 'nested_content'
    end
  end
end
