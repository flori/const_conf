# A module that defines custom exception classes for configuration-related
# errors in the ConstConf system. ConstConf::Errors is then included in
# ConstConf.
#
# This module provides a hierarchy of exception classes that are used
# throughout the ConstConf configuration management library to signal various
# types of configuration issues, such as missing required values or
# descriptions. These exceptions help ensure that applications using ConstConf
# are properly configured and can handle configuration errors gracefully.
#
# @example Handling configuration errors
#   begin
#     # Code that may raise a ConstConf::ConfigurationError
#   rescue ConstConf::ConfigurationError => e
#     # Handle the configuration error appropriately
#   end
module ConstConf::Errors
  # A base exception class for configuration-related errors in the ConstConf module.
  #
  # This class serves as the parent class for all custom exceptions raised within
  # the ConstConf configuration management system. It provides a common ancestor
  # for exception handling and allows for specific configuration error types to
  # be distinguished from general errors.
  #
  # @example Handling a configuration error
  #   begin
  #     # Code that may raise a ConstConf::ConfigurationError
  #   rescue ConstConf::ConfigurationError => e
  #     # Handle the configuration error appropriately
  #   end
  class ConfigurationError < StandardError; end

  # A custom exception class used to signal that a required configuration value
  # has not been provided.
  #
  # This exception is raised when a configuration setting marked as required
  # has not been configured with a valid value, helping to ensure that
  # essential application settings are properly defined before runtime.
  #
  # @example Handling a required configuration error
  #   begin
  #     # Code that may raise RequiredValueNotConfigured
  #   rescue RequiredValueNotConfigured => e
  #     # Handle the missing required configuration
  #   end
  class RequiredValueNotConfigured < ConfigurationError ; end

  # A custom exception class used to signal that a required configuration
  # description has not been provided.
  #
  # This exception is raised when essential application settings are not
  # properly documented before runtime.
  #
  # @example Handling a required description error
  #   begin
  #     # Code that may raise RequiredDescriptionNotConfigured
  #   rescue RequiredDescriptionNotConfigured => e
  #     # Handle the missing required configuration description
  #   end
  class RequiredDescriptionNotConfigured < ConfigurationError ; end

  # A custom exception class raised when a configuration setting is defined
  # more than once in the ConstConf system.
  #
  # This exception is used to prevent duplicate configuration settings from
  # being registered, ensuring that each environment variable name maps to a
  # single configuration value within a given module hierarchy.
  #
  # @example Handling a duplicate setting definition
  #   begin
  #     # Code that would cause a SettingAlreadyDefined error
  #   rescue ConstConf::SettingAlreadyDefined => e
  #     # Handle the duplicate setting appropriately
  #   end
  class SettingAlreadyDefined < ConfigurationError; end

  # A custom exception class raised when a configuration setting's confirmation
  # check fails.
  #
  # This exception is used to signal that a configuration setting has failed its
  # confirmation check, which is a custom validation logic defined for the setting.
  # It inherits from ConfigurationError and is part of the error handling mechanism
  # within the ConstConf system to ensure settings meet specific criteria beyond
  # basic required and default value checks.
  #
  # @example Handling a setting check failure
  #   begin
  #     # Code that may raise SettingCheckFailed
  #   rescue ConstConf::SettingCheckFailed => e
  #     # Handle the failed validation check appropriately
  #   end
  class SettingCheckFailed < ConfigurationError; end
end
