# A configuration setting definition that encapsulates the properties and
# behavior of a single environment variable-based setting.
#
# The Setting class provides a structured way to define, validate, and
# retrieve configuration values from environment variables, including support
# for default values, required validation, decoding logic, and descriptive
# metadata.
#
# @example Defining a configuration setting
#   Setting.new(name: 'DATABASE_URL', prefix: 'APP') { |s|
#     description = 'The database connection string'
#     required true
#   }
class ConstConf::Setting
  extend ConstConf::SettingAccessor
  include DSLKit::BlockSelf

  # Initializes a new Setting instance with the given name and prefix.
  #
  # @param name [Array<String>, String] the name components for the setting
  # @param prefix [String, nil] the optional upcassed prefix to use when
  # constructing environment variable names
  # @yield [] optional block to configure the setting
  def initialize(name:, prefix: nil, &block)
    @parent_namespace = block_self(&block)
    @name             = Array(name) * '::'
    self.prefix(prefix)

    block and self.class.enable_setter_mode { instance_eval(&block) }
  end

  # The name reader accessor returns the name of the setting.
  #
  # @return [String] the constructed environment variable name
  attr_reader :name

  # The parent_namespace reader accessor returns the parent namespace of the
  # setting.
  #
  # @return [Module, nil] the parent namespace module, or nil if not set
  attr_reader :parent_namespace

  # The prefix reader accessor returns the configured prefix for the setting.
  #
  # @return [String, nil] the prefix value, or nil if not set
  setting_accessor :prefix,
    transform: -> value { value.ask_and_send_or_self(:upcase) }

  # The activated reader and writer accessor for configuration settings.
  #
  # This method provides access to the activated state of a configuration
  # setting, which determines whether the setting should be considered active
  # based on its current value or other conditions. It defaults to `:present?`
  # of not set.
  #
  # @return [Object] the updated activated state value
  # @see #active?
  setting_accessor :activated, :present?

  # Checks if the configuration setting is active based on its activated state.
  #
  # This method evaluates whether the configuration setting is considered
  # active by examining its activated property. If activated is set to true, it
  # checks if the setting's value is present. If activated is a Symbol, it
  # sends that symbol as a message to the value and returns the result. If
  # activated is a Proc, it evaluates the proc with or without the value
  # depending on its arity. For any other value, it returns false.
  #
  # @return [Boolean] true if the setting is active according to its activated
  # state, false otherwise
  def active?
    case activated
    when true
      value.present?
    when Symbol
      !!value.send(activated)
    when Proc
      if activated.arity == 1
        !!activated.(value)
      else
        !!activated.()
      end
    else
      false
    end
  end

  # Sets or retrieves the confirmation check logic for the configuration
  # setting.
  #
  # This method provides access to the check configuration, which is used to
  # validate that a setting meets certain criteria beyond basic required and
  # default value checks. The check can be a Proc that evaluates to true,
  # :unchecked_true (truthy), or false, allowing for custom validation logic. It
  # deffaults to true, if not set otherwise.
  #
  # @return [Proc, Object] the current check configuration value
  setting_accessor :check, -> setting { :unchecked_true }

  # Checks if the configuration setting passes its validation check.
  #
  # @return [Boolean, Symbol] true if the setting's check logic evaluates to true,
  # false or false if not. I no check was defined, returns :unchecked_true.
  # @see check
  def checked?
    instance_eval(&check)
  end

  # Checks if a configuration setting has been provided with a valid value.
  #
  # @return [Boolean] true if the setting has either an environment variable
  # value or a default value that is not nil, false otherwise
  def value_provided?
    !configured_value_or_default_value.nil?
  end

  # Sets whether the setting is required.
  #
  # @param value [Boolean, Proc] the value to set for the required flag
  #   - true/false: Simple boolean requirement check
  #   - Proc: Dynamic validation logic that can be evaluated in two ways:
  #     * With arity 1: Called with the setting's value (e.g., `->(value) { value.present? }`)
  #     * With arity 0: Called without arguments (e.g., `-> { some_value.present? }`)
  # @return [Boolean, Proc] returns the value that was set
  # @method required(value = nil, &block)
  # @see #required?
  setting_accessor :required, false

  # Checks if the setting has a required value configured or as a default
  # value.
  #
  # This method evaluates whether the configuration setting is marked as required
  # and determines if a valid value is present. It handles different forms of
  # required specification including boolean flags and Proc objects that can
  # perform dynamic validation based on the current value or context.
  #
  # @return [Boolean] true if the setting is marked as required and has a valid
  #   value according to its validation logic, false otherwise
  def required?
    !!case required
      when Proc
        if required.arity == 1
          required.(configured_value_or_default_value)
        else
          required.()
        end
      else
        required
      end
  end

  # Checks if the setting has a required value configured.
  #
  # @return [Boolean] true if the setting is marked as required and has a valid
  # value, false otherwise
  setting_accessor :sensitive, false

  alias sensitive? sensitive

  # Sets or retrieves the description for the configuration setting.
  #
  # @return [String] the current description value
  setting_accessor :description

  # Sets or retrieves the decoding configuration for the setting.
  #
  # @param value [Proc, nil] the decoding configuration value
  #   - Proc: A function that transforms the raw environment variable value
  #   - nil: No decoding applied
  # @return [Proc, nil] the current decoding configuration value
  # @method decode(value = nil)
  # @see #decoding?
  setting_accessor :decode

  # Checks if the setting has decoding logic configured.

  # @return [Boolean] true if the setting has a Proc-based decoding configuration,
  #   false otherwise
  def decoding?
    !!decode&.is_a?(Proc)
  end

  # Sets the default value for the configuration option.
  #
  # @param value [Object] the default value to use when no environment
  # variable is set
  setting_accessor :default

  # Returns the default value for the configuration option, evaluating it if
  # it's a Proc.
  #
  # @return [Object] the default value, or the result of evaluating the
  # default if it's a Proc
  def default_value
    case default
    when Proc
      default.()
    else
      default
    end
  end

  # Sets whether this configuration option should be ignored when reading
  # values from environment variables with name env_var_name.
  #
  # @param value [Boolean] true if the configuration option should be
  # ignored, false otherwise
  setting_accessor :ignored

  # Checks if the configuration setting is marked as ignored.
  #
  # This method returns true if the setting has been explicitly marked to be
  # ignored when reading values from environment variables, indicating that
  # it should be skipped during configuration processing.
  #
  # @return [Boolean] true if the setting is ignored, false otherwise
  def ignored?
    !!ignored
  end

  # Generates the environment variable name for this configuration option by
  # constructing it from the configured prefix and name components, replacing
  # namespace separators with underscores.
  #
  # @return [String] the constructed environment variable name
  def env_var_name
    prefix = @prefix.full? { "#{it}::" }.to_s
    name.sub(/^#{parent_namespace}::/,  prefix).gsub(/::/, ?_)
  end

  # Retrieves the value of the environment variable associated with this
  # configuration option.
  #
  # @return [String, nil] the value of the environment variable if it exists,
  # or nil if not set
  def env_var
    ENV[env_var_name]
  end

  # Returns the configured value for the setting, considering ignore status and
  # environment variable presence.
  #
  # @return [String, nil] the environment variable value if the setting is not
  # ignored and the environment variable is set, nil otherwise
  def configured_value
    if ignored
      nil
    elsif env_var.nil?
      nil
    else
      env_var
    end
  end

  # Checks if the configuration setting has been configured with a value.
  #
  # This method determines whether the configuration setting has been provided
  # with a value, either through an environment variable or a default value.
  # It returns true if a valid value is present, and false otherwise.
  #
  # @return [Boolean] true if the setting has been configured with a value,
  #   false otherwise
  def configured?
    !configured_value.nil?
  end

  # Returns the configured value for the setting, or falls back to the default
  # value if not configured.
  #
  # @return [Object, nil] the configured value if present, otherwise the
  # default value, or nil if neither is set
  def configured_value_or_default_value
    configured_value || default_value
  end

  # Retrieves the effective value for the configuration setting.
  #
  # This method determines the appropriate value for the configuration
  # setting by first checking if the setting is not ignored and an
  # environment variable value is present. If so, it uses the environment
  # variable value. Otherwise, it falls back to the default value. The
  # resulting value is then passed through any configured decoding logic.
  #
  # @return [Object] the effective configuration value after applying any
  #   decoding logic, or the default value if no environment variable is set
  def value
    decoded_value(configured_value_or_default_value)
  end

  # Confirms that the configuration setting and its parent module meet all
  # required criteria.
  #
  # This method ensures that the setting has a description, that its parent
  # module (if it's a ConstConf module) has a description, that any required
  # values are provided, and that the setting passes its confirmation check. It
  # raises appropriate exceptions if any of these validation rules are not
  # satisfied.
  #
  # @return [ ConstConf::Setting ] returns self if all validations pass
  #
  # @raise [ ConstConf::RequiredDescriptionNotConfigured ] if the setting's description
  #   is blank or the parent module's description is missing
  # @raise [ ConstConf::RequiredValueNotConfigured ] if the setting is required but no
  #   value is provided
  # @raise [ ConstConf::SettingCheckFailed ] if the setting's check fails
  def confirm!
    if parent_namespace.is_a?(Module) && parent_namespace < ConstConf
      parent_namespace.description.present? or
        raise ConstConf::RequiredDescriptionNotConfigured,
        "required description for ConstConf module #{parent_namespace} not configured"
    end
    if description.blank?
      raise ConstConf::RequiredDescriptionNotConfigured,
        "required description for setting #{env_var_name} not configured"
    end
    if required? && !value_provided?
      raise ConstConf::RequiredValueNotConfigured,
        "required value for #{env_var_name} not configured"
    end
    unless checked?
      raise ConstConf::SettingCheckFailed, "check failed for #{name} setting"
    end
    self
  end

  # Displays a textual representation of this configuration setting.
  #
  # This method generates a formatted tree-like view of the current configuration
  # setting, including its name, description, environment variable name, and
  # associated metadata such as prefix, default value, and configuration status.
  # The output can be directed to a specified IO object or displayed to the
  # standard output.
  #
  # @param io [IO, nil] the IO object to write the output to; if nil, uses STDOUT
  def view(io: nil)
    parent_namespace.view(object: self, io:)
  end

  # Returns the string representation of the tree structure.
  #
  # This method generates a formatted string representation of the tree node
  # and its children, including the node's name and any associated value, with
  # proper indentation to show the hierarchical relationship between nodes.
  #
  # @return [String] a multi-line string representation of the tree structure
  def to_s
    io = StringIO.new
    view(io:)
    io.string
  end

  alias inspect_original inspect

  # The inspect method returns a string representation of the object, with
  # special handling for IRB colorization.
  #
  # @return [String] the string representation of the object,
  #   optionally stripped of ANSI color codes when used in IRB with
  #   colorization enabled
  def inspect
    if defined?(IRB) && IRB.conf[:USE_COLORIZE]
      Term::ANSIColor.uncolor(to_s)
    else
      to_s
    end
  end

  private

  # Decodes a value using the configured decoder if present, otherwise returns the value as-is.
  #
  # @param value_arg [Object] the value to be decoded
  # @return [Object] the decoded value or the original value if no decoding is
  # configured
  def decoded_value(value_arg)
    if decode.is_a?(Proc)
      decode.(value_arg)
    else
      value_arg
    end
  end
end
