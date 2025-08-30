require 'json'

# A module that provides functionality for reading and parsing JSON file
# contents as configuration values.
#
# The JSONPlugin module extends the ConstConf::Setting class to enable
# configuration settings that are sourced from JSON files. This allows for
# structured configuration data to be loaded from files and used within the
# application's configuration system, supporting both standard JSON parsing and
# environment-specific configuration loading.
module ConstConf::JSONPlugin
  # Reads and parses a JSON file, optionally with environment-specific loading
  #
  # This method attempts to read and parse a JSON file at the specified path.
  # It supports environment-specific configuration loading when the env
  # parameter is provided. The method uses thread synchronization to ensure
  # safe access to the ComplexConfig provider.
  #
  # @param path [String] the filesystem path to the JSON file to be read
  # @param required [Boolean] whether the file is required to exist, defaults to false
  #
  # @return [Object, nil] the parsed JSON content as a Ruby object, or nil if
  # the file doesn't exist and required is false
  #
  # @raise [ConstConf::RequiredValueNotConfigured] if the file does not exist
  # and required is true
  # @raise [ConstConf::RequiredValueNotConfigured] if env is true and RAILS_ENV
  # is not set and no explicit environment is provided
  def json(path, required: false, object_class: JSON::GenericObject)
    if File.exist?(path)
      JSON.load_file(path, object_class:)
    elsif required
      raise ConstConf::RequiredValueNotConfigured,
        "JSON file required at path #{path.to_s.inspect}"
    end
  end
end
