# A module that provides functionality for reading file contents from
# configuration directories, supporting XDG Base Directory Specification
# compliance.
#
# The DirPlugin extends the ConstConf::Setting class to enable configuration
# settings that are sourced from files within named directories. This allows
# for more complex and secure configuration management, particularly useful for
# storing sensitive data or structured configs in files rather than environment
# variables.
#
# @example Basic usage with file reading
#   module APP
#     include ConstConf
#     plugin ConstConf::DirPlugin
#
#     CONFIG_FILE = set do
#       description 'Configuration from file'
#       default dir('myapp', 'config.yaml')
#       decoding { |s| YAML.load(s) }
#     end
#   end
#
# @example XDG-compliant directory structure
#   module APP
#     include ConstConf
#     plugin ConstConf::DirPlugin
#
#     XDG_CONFIG_HOME = set do
#       description 'XDG Config HOME'
#       prefix ''
#     end
#
#     API_KEY = set do
#       description 'API Key from XDG config'
#       default dir('myapp', 'api_key.txt', env_var: APP::XDG_CONFIG_HOME?)
#     end
#   end
#
# @see ConstConf::Setting
module ConstConf::DirPlugin
  # A configuration directory handler that provides methods for deriving
  # directory paths, joining paths, and reading file contents from a specified
  # directory structure.
  #
  # The ConfigDir class is designed to work with the XDG Base Directory
  # Specification and supports reading files from directories with optional
  # environment variable configuration for the root path. It provides a clean
  # interface for accessing configuration files in a structured way.
  class ConfigDir
    # Initializes a new instance with a name and environment variable
    # configuration.
    #
    # @param name [String] the name used to derive the directory path
    # @param root_path [String, nil] the root path to use for deriving the directory path
    # @param env_var [String, nil] the environment variable value to use
    # @param env_var_name [String, nil] the name of the environment variable to look up
    #
    # @raise [ArgumentError] if env_var and env_var_name were given.
    def initialize(name, root_path: nil, env_var:, env_var_name: nil)
      !env_var.nil? && !env_var_name.nil? and
        raise ArgumentError,
        "need either the value of an env_var or the name env_var_name of an env_var"
      if env_var.nil? && !env_var_name.nil?
        env_var = ENV[env_var_name]
      end
      root_path ||= env_var
      @directory_path = derive_directory_path(name, root_path)
    end

    # Returns the string representation of the configuration directory path.
    #
    # @return [ String ] the path of the configuration directory as a string
    def to_s
      @directory_path.to_s
    end

    # Joins the directory path with the given path and returns the combined
    # result.
    #
    # @param path [ String ] the path to be joined with the directory path
    #
    # @return [ Pathname ] the combined path as a Pathname object
    def join(path)
      @directory_path + path
    end
    alias + join

    # Reads the content of a file at the given path within the configuration
    # directory.
    #
    # If the file exists, it returns the file's content as a string encoded in
    # UTF-8. If a block is given and the file exists, it opens the file and
    # yields to the block.
    # If the file does not exist and a default value is provided, it returns
    # the default. If a block is given and the file does not exist, it yields a
    # StringIO object containing
    # the default value to the block.
    #
    # @param path [ String ] the path to the file relative to the configuration
    # directory
    # @param default [ String, nil ] the default value to return if the file
    # does not exist
    #
    # @yield [ io ]
    #
    # @return [ String, nil ] the content of the file or the default value if
    # the file does not exist
    def read(path, default: nil, required: false, &block)
      full_path = join(path)
      if File.exist?(full_path)
        if block
          File.open(full_path, &block)
        else
          File.read(full_path, encoding: 'UTF-8')
        end
      else
        required and raise ConstConf::RequiredValueNotConfigured,
          "require file at #{full_path.to_s.inspect}"
        if default && block
          block.(StringIO.new(default))
        else
          default
        end
      end
    end

    private

    # Derives the full directory path by combining the root path and the given
    # name.
    #
    # @param name [ String ] the name of the directory to be appended to the root path
    # @param root_path [ String, nil ] the root path to use; if nil, the default root path is used
    #
    # @return [ Pathname ] the combined directory path as a Pathname object
    def derive_directory_path(name, root_path)
      root = if path = root_path
               Pathname.new(path)
             else
               Pathname.new(default_root_path)
             end
      root + name
    end

    # Returns the default configuration directory path based on the HOME
    # environment variable.
    #
    # This method constructs and returns a Pathname object pointing to the
    # standard configuration directory location, which is typically
    # $HOME/.config.
    #
    # @return [ Pathname ] the default configuration directory path
    def default_root_path
      Pathname.new(ENV.fetch('HOME')) + '.config'
    end
  end

  # The dir method creates and reads a configuration directory setting.
  #
  # This method initializes a ConfigDir instance with the provided name and
  # environment variable configuration, then reads the directory path with
  # optional default and required validation settings.
  #
  # @param name [String] the name of the configuration directory
  # @param path [String] the filesystem path to the directory
  # @param env_var [String, nil] the environment variable name to use for configuration
  # @param env_var_name [String, nil] the full environment variable name to use
  # @param default [Object] the default value to use when no configuration is provided
  # @param required [Boolean] whether the directory path is required to exist
  #
  # @return [Object] the result of reading path from the directory name
  def dir(name, path, env_var: nil, env_var_name: nil, default: nil, required: false)
    ConfigDir.new(name, env_var:, env_var_name:).read(path, default:, required:)
  end
end
