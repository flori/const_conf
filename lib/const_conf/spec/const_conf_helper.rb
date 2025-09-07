# Sets constants and their configured values for testing purposes.
#
# This module provides a helper method for temporarily overriding constant
# values during testing, including nested constants within modules. It ensures
# that specified constants exist before stubbing them and handles configuration
# of boolean-check methods for nested constants.
#
# @example
#   const_conf_as('FooConfig::DATABASE::ENABLED' => true)
module ConstConf::ConstConfHelper
  # Sets constants and their configured values for testing purposes.
  #
  # This method is designed to facilitate testing by allowing test code to
  # temporarily override the values of constants, including nested constants
  # within modules. It ensures that the specified constants exist before
  # attempting to stub them, and also handles the configuration of
  # boolean-check methods for nested constants.
  #
  # @param config_hash [Hash] a hash mapping constant names (as strings) to
  # their intended values
  def const_conf_as(config_hash)
    config_hash.each do |const_name, value|
      Object.const_defined?(const_name) or
        raise NameError, "constant #{const_name} does not exist"
      stub_const("#{const_name}", value)
      const_parts = const_name.split('::')
      if const_parts.size > 1
        parent_const_name = const_parts[0..-2] * '::'
        Object.const_defined?(parent_const_name) or raise NameError,
          "parent constant #{parent_const_name} does not exist"
        parent_const = Object.const_get(parent_const_name)
        allow(parent_const).to receive("#{const_parts.last}?").
          and_return(value)
      end
    end
  end
end
