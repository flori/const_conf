# A module that provides functionality for defining setting accessors within
# configuration modules.
#
# The SettingAccessor module enables the creation of dynamic getter and setter
# methods for configuration settings, supporting features like default values,
# block evaluation, and lazy initialization. It is designed to be included in
# classes or modules that need to manage configuration properties with ease and
# consistency.
#
# @example Defining a setting accessor
#   class MyClass
#     extend ConstConf::SettingAccessor
#     setting_accessor :my_setting, 'default_value'
#   end
module ConstConf::SettingAccessor
  # @!attribute [rw] setter_mode
  #   Thread-local flag that controls behavior during configuration block
  #   evaluation.
  #
  #   When {setter_mode} is true (during {ConstConf::Setting} initialization),
  #   the accessor enforces that required settings must be explicitly provided
  #   rather than falling back to defaults. This prevents accidental
  #   configuration of settings with nil values when they should be explicitly
  #   set.
  #
  #   @see ConstConf::SettingAccessor#setting_accessor
  #   @see ConstConf::Setting#initialize
  #   @return [Boolean] true when in setter mode, false otherwise
  thread_local :setter_mode, false

  # Enables setter mode for configuration block evaluation.
  #
  # This method temporarily sets the setter_mode flag to true, which affects
  # how setting accessors behave during configuration block evaluation. When
  # setter mode is active, certain validation rules are applied to ensure that
  # required settings are explicitly provided rather than falling back to
  # defaults.
  #
  # @return [Object] the return value of the block passed to this method
  def enable_setter_mode
    old, self.setter_mode = self.setter_mode, true
    yield
  ensure
    self.setter_mode = old
  end

  # Defines a setting accessor method that creates a dynamic getter/setter for
  # configuration values.
  #
  # This method generates a singleton method that provides access to a
  # configuration setting, supporting default values, block evaluation for
  # defaults, and lazy initialization of the setting's value. The generated
  # method can be used to retrieve or set the value of the configuration
  # setting, with support for different types of default values including Proc
  # objects which are evaluated when needed.
  #
  # @param name [Symbol] the name of the setting accessor to define
  # @param default [Object] the default value for the setting, can be a Proc
  # that gets evaluated
  # @yield [] optional block to evaluate for default value when no explicit
  # default is provided
  # @return [Symbol] always returns the name as Symbol as it defines a method
  def setting_accessor(name, default = nil, transform: nil, &block)
    variable = "@#{name}"
    define_method(name) do |arg = :not_set, &arg_block|
      was_not_set = if arg.equal?(:not_set)
                      arg = nil
                      true
                    else
                      false
                    end
      if arg_block
        arg.nil? or raise ArgumentError,
          'only either block or positional argument allowed'
        arg = arg_block
      end
      if arg.nil?
        if self.class.respond_to?(:setter_mode)
          if self.class.setter_mode && was_not_set
            raise ArgumentError,
              "need an argument for the setting #{name.inspect} "\
              "of #{self}, was nil"
          end
        end
        result =
          if instance_variable_defined?(variable)
            instance_variable_get(variable)
          end
        if result.nil?
          result = if default.nil?
                     block && instance_eval(&block)
                   elsif default
                     default
                   end
          instance_variable_set(variable, result)
          result
        else
          result
        end
      else
        arg = transform.(arg) if transform
        instance_variable_set(variable, arg)
      end
    end
  end
end
