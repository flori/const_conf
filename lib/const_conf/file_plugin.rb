# A module that provides functionality for reading file contents as
# configuration values.
#
# The FilePlugin module extends the ConstConf::Setting class to enable
# configuration settings that are sourced from file contents rather than
# environment variables. This allows for more complex configuration data, such
# as SSL certificates or API keys, to be loaded from files and used within the
# application's configuration system.
module ConstConf::FilePlugin
  # Reads the content of a file and returns it as a string.
  #
  # This method attempts to read the contents of a file specified by the given
  # path. If the file exists, its content is returned as a string. If the file
  # does not exist and the required flag is set to true, a
  # RequiredValueNotConfigured exception is raised.
  #
  # @param path [String] the filesystem path to the file to be read
  # @param required [Boolean] whether the file is required to exist, defaults
  # to false
  #
  # @return [String, nil] the content of the file if it exists, or nil if it
  # doesn't and required is false
  #
  # @raise [ConstConf::RequiredValueNotConfigured] if the file does not exist
  # and required is true
  def file(path, required: false, strip: false)
    if File.exist?(path)
      value = File.read(path)
      strip and value.strip!
      value
    elsif required
      raise ConstConf::RequiredValueNotConfigured,
        "file required at path #{path.to_s.inspect}"
    end
  end
end
