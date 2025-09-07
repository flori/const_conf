# An extension that enables loading environment variable values from files in
# a directory structure, where each file's basename becomes an environment
# variable name.
#
# This extension is particularly useful for implementing a pattern, where each
# environment variable is stored in its own file with the same name as the
# variable. For example:
#
#   ./env/DATABASE_URL    # contains: postgresql://localhost/myapp
#   ./env/API_KEY         # contains: sk-1234567890abcdef1234567890abcdef
#
# Usage:
#   module AppConfig
#     include ConstConf
#
#     description 'Application Configuration'
#
#     module EnvDir
#       extend ConstConf::EnvDirExtension
#
#       description 'All variables loaded from .env directory'
#
#       # Load all environment variables from .env/*
#       load_dotenv_dir('.env/*') {}
#     end
#   end
#
# The loaded settings are automatically:
# - Marked as sensitive (since they might contain secrets)
# - Required (files must exist to be loaded)
# - Chomped to remove trailing whitespace
# - Named using the file basename in uppercase and without a prefix.
#
# This extension works well alongside manually-defined settings, if you put it
# into a nested module at the end of your ConstConf config. Settings defined
# explicitly with `set do` blocks before this module take precedence over
# auto-loaded ones, allowing for a hybrid approach where critical configuration
# is documented and validated, while additional environment variables can be
# loaded automatically from files.
#
# The loaded settings appear in AppConfig.view() with proper descriptions
# showing their source file locations, making it easy to see what configuration
# is being used.
module ConstConf::EnvDirExtension
  include ConstConf::FilePlugin

  # Loads environment variable values from dotenv-style files into
  # configuration constants.
  #
  # This method processes glob patterns to find files, reads their content
  # using the FilePlugin, and defines configuration settings for each file's
  # content. It automatically creates constants with uppercase names based on
  # the filename and configures them as required and sensitive settings with
  # chomped values.
  #
  # @param globs [Array<String>] glob patterns to match files containing
  # environment variables
  # @yield [ binding ] yields the binding of the caller to allow evaluation in
  # the correct context
  # @yieldparam binding [Binding] the binding to evaluate constants in
  def load_dotenv_dir(*globs, &block)
    block or raise ArgumentError, '&block argument is required'
    globs.each do |glob|
      Dir[glob].each do |path|
        my_file = file(path, required: true)
        eval('self', block.__send__(:binding)).class_eval do
        name = File.basename(path).upcase
        const_set(
          name,
          set do
            prefix ''
            description "Value of #{name.inspect} from #{File.dirname(path).inspect}"
            default my_file
            decode(&:chomp)
            required true
            sensitive true
          end
        )
        rescue ConstConf::SettingAlreadyDefined
        end
      end
    end
    self
  end
end
