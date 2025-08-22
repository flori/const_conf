require 'spec_helper'

describe ConstConf::EnvDirExtension do
  module TestConfig
    include ConstConf

    description 'Test Configuration'

    module EnvDir
      extend ConstConf::EnvDirExtension
      description 'All variables loaded from .env directory'

      load_dotenv_dir('spec/assets/.env/*') {}
    end
  end

  describe '#load_dotenv_dir' do
    it 'creates constants with proper naming and metadata including descriptions' do
      # Verify the setting exists and has correct properties
      expect(TestConfig::EnvDir::API_KEY).to eq "sk-1234567890abcdef1234567890abcdef"

      # Test that it's marked as sensitive (since it's a secret)
      setting = TestConfig::EnvDir.settings['API_KEY']
      expect(setting.sensitive?).to be true

      # Test that it has proper description from the file
      expect(setting.description).to include("Value of \"API_KEY\" from")
      expect(TestConfig.settings.size).to eq 0
      expect(TestConfig::EnvDir.settings.size).to eq 1
    end

    it 'handles duplicate definitions gracefully with proper error handling' do
      module TestConfigWithManualSetting
        include ConstConf

        description 'Test Configuration'

        # Manually define first (should take precedence)
        API_KEY = set  do
          description 'Manually defined API_KEY'
          prefix ''

          default "manual_value"
        end

        module EnvDir
          extend ConstConf::EnvDirExtension
          description 'All variables loaded from .env directory'

          load_dotenv_dir('spec/assets/.env/*') {}
        end
      end
      # Should use the manual definition, not the file content
      expect(TestConfigWithManualSetting::API_KEY).to eq "manual_value"
      expect(TestConfigWithManualSetting.settings.size).to eq 1
      expect(TestConfigWithManualSetting::EnvDir.settings.size).to eq 0
    end
  end
end
