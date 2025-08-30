require 'complex_config'

# A module that provides functionality for reading and parsing YAML file
# contents as configuration values.
#
# The YAMLPlugin module extends the ConstConf::Setting class to enable
# configuration settings that are sourced from YAML files. This allows for
# structured configuration data to be loaded from files and used within the
# application's configuration system, supporting both standard YAML parsing and
# environment-specific configuration loading.
module ConstConf::YAMLPlugin
  include ComplexConfig::Provider::Shortcuts

  # Reads and parses a YAML file, optionally with environment-specific loading
  #
  # This method attempts to read and parse a YAML file at the specified path.
  # It supports environment-specific configuration loading when the env
  # parameter is provided. The method uses thread synchronization to ensure
  # safe access to the ComplexConfig provider.
  #
  # @param path [String] the filesystem path to the YAML file to be read
  # @param required [Boolean] whether the file is required to exist, defaults to false
  # @param env [Boolean, String] whether to load environment-specific configuration,
  #   can be true to use RAILS_ENV or a specific environment string
  #
  # @return [Object, nil] the parsed YAML content as a Ruby object, or nil if
  # the file doesn't exist and required is false
  #
  # @raise [ConstConf::RequiredValueNotConfigured] if the file does not exist
  # and required is true
  # @raise [ConstConf::RequiredValueNotConfigured] if env is true and RAILS_ENV
  # is not set and no explicit environment is provided
  def yaml(path, required: false, env: false)
    if File.exist?(path)
      ConstConf.monitor.synchronize do
        config_dir = File.dirname(path)
        ComplexConfig::Provider.config_dir = config_dir
        ext  = File.extname(path)
        name = File.basename(path, ext)
        if env
          env == true and env = ENV['RAILS_ENV']
          if env
            complex_config_with_env(name, env)
          else
            raise ConstConf::RequiredValueNotConfigured,
              "need an environment string specified, via env var RAILS_ENV or manually"
          end
        else
          complex_config(name)
        end
      end
    elsif required
      raise ConstConf::RequiredValueNotConfigured,
        "YAML file required at path #{path.to_s.inspect}"
    end
  end
end
