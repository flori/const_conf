require 'tins/xt'
require 'rails'

# A configuration management module that provides environment variable-based
# settings with validation and thread-safe operations.
#
# ConstConf enables defining configuration settings through environment
# variables, including support for default values, required validation,
# decoding logic, and descriptive metadata. It offers thread-safe registration
# and retrieval of configuration values while providing integration with Rails
# application initialization cycles.
module ConstConf
end
require 'const_conf/setting_accessor'
require 'const_conf/errors'
require 'const_conf/setting'
require 'const_conf/file_plugin'
require 'const_conf/dir_plugin'
require 'const_conf/json_plugin'
require 'const_conf/yaml_plugin'
require 'const_conf/env_dir_extension'
require 'const_conf/tree'
require 'const_conf/railtie'

module ConstConf
  include ConstConf::Errors

  class << self
    # Returns the monitor instance for thread synchronization.
    #
    # This method provides a singleton Monitor instance that can be used to
    # synchronize access to shared resources across threads. It ensures that
    # only one thread can execute critical sections of code at a time.
    #
    # @return [Monitor] the singleton Monitor instance used for thread synchronization
    def monitor
      @monitor ||= Monitor.new
    end

    # The module_files accessor provides read and write access to the
    # module_files instance variable.
    #
    # This method serves as a getter and setter for the module_files attribute,
    # which stores a hash mapping modules to their corresponding file paths.
    #
    # @return [Hash, nil] the current value of the module_files instance variable
    attr_accessor :module_files

    # Registers a module-file mapping in the global registry.
    #
    # This method associates a module with its corresponding file path in the
    # global module_files hash. The registration is performed in a thread-safe
    # manner using the monitor for synchronization.
    #
    # @param configuration [ Module ] the module to register
    # @param file [ String ] the file path associated with the module
    def register(configuration, file)
      monitor.synchronize do
        module_files[configuration] ||= file
      end
    end

    # Destroys all registered configuration modules and returns their file
    # paths.
    #
    # This method synchronizes access to the global configuration registry and
    # removes all registered modules from their respective parent namespaces.
    # It collects the file paths associated with each module before removing
    # them, returning an array of the collected file paths.
    #
    # @return [Array<String>] an array containing the file paths of the destroyed modules
    def destroy
      monitor.synchronize do
        files = []
        while pair = ConstConf.module_files.shift
          modul, file = pair
          if modul.module_parent.const_defined?(modul.name)
            modul.module_parent.send(:remove_const, modul.name)
          end
          files << file
        end
        files
      end
    end

    # Reloads all registered configuration modules by destroying them and
    # re-loading their associated files.
    #
    # This method ensures that all configuration modules currently registered
    # with ConstConf are destroyed and then reloaded from their respective
    # files. It performs this operation in a thread-safe manner using the
    # monitor for synchronization.
    def reload
      monitor.synchronize { destroy.each { load it } }
      nil
    end
  end
  self.module_files = {}

  extend ActiveSupport::Concern

  class_methods do
    extend ConstConf::SettingAccessor

    # The plugin method includes a module into the ConstConf::Setting class.
    #
    # This method allows for extending the functionality of configuration
    # settings by including additional modules that provide extra behavior or
    # methods. It is typically used to add custom validation, encoding, or
    # other capabilities to settings defined within the ConstConf system.
    #
    # @param plugin [ Module ] the module to be included in ConstConf::Setting
    #
    # @return [ Class ] returns the current class (self) to allow for method chaining
    def plugin(plugin)
      ConstConf::Setting.class_eval { include plugin }
      self
    end

    # Handles the addition of constants to a module, configuring them as
    # settings when appropriate.
    #
    # This method is invoked automatically when a constant is added to a module
    # that includes ConstConf. It processes the constant by checking if it's a
    # Module and including ConstConf in it. If there's a pending configuration
    # block for the constant, it creates a Setting instance, registers it, and
    # sets the constant's value accordingly. It also defines helper methods to
    # query the setting and its configuration status.
    #
    # @param id [ Symbol ] the name of the constant being added
    def const_added(id)
      id = id.to_sym
      if const = const_get(id) and const.is_a?(Module)
        nested_module_constants << id
        const.class_eval do
          include ConstConf
        end
        prefix = [ self, *module_parents ].find {
          !it.prefix.nil? and break it.prefix
        }
        const.prefix [ prefix, const.name.sub(/.*::/, '') ].select(&:present?) * ?_
      end
      ConstConf.monitor.synchronize do
        if setting_block = last_setting
          self.last_setting = nil
          remove_const(id)
          prefix = [ self, *module_parents ].find {
            !it.prefix.nil? and break it.prefix
          }
          setting = Setting.new(name: [ name, id ], prefix:, &setting_block)
          if previous_setting = outer_configuration.setting_for(setting.env_var_name)
            raise ConstConf::SettingAlreadyDefined,
              "setting for env var #{setting.env_var_name} already defined in #{previous_setting.name}"
          end
          settings[setting.env_var_name] = setting
          const_set id, setting.value
          my_configuration = self
          singleton_class.class_eval {
            define_method("#{id}!") { setting }
            my_configuration.send("#{id}!")
            define_method("#{id}?") { (setting.value if setting.active?) }
            my_configuration.send("#{id}?")
          }
          setting.confirm!
        end
      end
      super if defined? super
    end

    # Removes a constant from the module and updates the nested module
    # constants set.
    #
    # This method removes a constant from its parent module using the standard
    # super mechanism and then removes the constant name from the
    # nested_module_constants set to maintain consistency in tracking nested
    # configuration modules.
    #
    # @param id [ Symbol ] the name of the constant to remove
    private def remove_const(id)
      super
      nested_module_constants.delete(id.to_sym)
    end

    # Sets or retrieves the description for a ConstConf module.
    #
    # This method provides access to the description attribute of a
    # configuration setting, which can be used to document the purpose and
    # usage of the module or nested module.
    #
    # @return [String, nil] the current description value
    setting_accessor :description

    # Declares a thread-local variable named last_setting.
    #
    # This method sets up a thread-local variable that can be used to store
    # temporary state within the current thread. It is typically used to
    # hold transient data that should not persist across threads.
    #
    # @param name [Symbol] the name of the thread-local variable to declare
    # @return [Object]
    thread_local :last_setting

    # Returns the settings hash for the configuration module.
    #
    # This method provides access to the internal hash that stores all configuration
    # settings defined within the module. It ensures the hash is initialized before
    # returning it, guaranteeing that subsequent accesses will return the same hash
    # instance.
    #
    # @return [Hash<String, ConstConf::Setting>] the hash containing all settings
    #   for this configuration module, keyed by their environment variable names
    def settings
      @settings ||= {}
    end

    # Returns the set of nested module constants for the configuration in
    # definition order.
    #
    # This method provides access to the internal storage that tracks which
    # constants within a configuration module are themselves modules that
    # include ConstConf. It ensures the set is initialized before returning it,
    # guaranteeing that subsequent accesses will return the same set instance.
    #
    # @return [Set<Symbol>] the set containing the names of nested module constants
    # @see #const_added
    # @see #nested_configurations
    # @see #all_configurations
    def nested_module_constants
      @nested_module_constants ||= Set[]
    end

    # The prefix reader accessor returns the configured prefix for the setting.
    #
    # @return [String, nil] the prefix value, or nil if not set
    setting_accessor(
      :prefix,
      transform: -> value { value.ask_and_send_or_self(:upcase) }
    ) do
      if module_parent == Object
        name.underscore.upcase
      end
    end

    # Sets the configuration block for the next constant definition.
    #
    # @param block [Proc] the configuration block to be stored
    # @return [nil] always returns nil
    def set(&block)
      if module_parent == Object and
          file = caller_locations.first.absolute_path and
          File.exist?(file)
        then
        ConstConf.register self, file
      end
      self.last_setting = block
      nil
    end

    # Finds the outer configuration module in the hierarchy.
    #
    # This method traverses up the module inheritance chain from the current
    # module, examining each module in reverse order of its parents, until it
    # finds a module that includes the ConstConf concern. This is useful for
    # identifying the top-level configuration module that contains the current
    # one.
    #
    # @return [ Module, nil ] the outer configuration module if found, or nil if none exists
    def outer_configuration
      [ self, *module_parents ].reverse_each.find { it < ConstConf }
    end

    # Returns an array containing all nested configuration modules recursively,
    # including itself.
    #
    # This method collects all configuration modules within the current module
    # and its hierarchy, returning them as an array. It utilizes the
    # each_nested_configuration iterator to traverse the module structure and
    # accumulate each configuration module into a result array.
    #
    # @return [Array<Module>] an array of all nested configuration modules
    #   found within the current module's hierarchy
    def all_configurations
      each_nested_configuration.reduce([]) { |array, configuration|
        array << configuration
      }
    end

    # Returns an array of the directly nested configuration modules that
    # include ConstConf.
    #
    # This method iterates through all constants defined in the current module,
    # identifies those that are modules and inherit from ConstConf, and returns
    # them as an array. It filters out any non-module constants or modules that
    # do not include the ConstConf concern.
    #
    # @return [ Array<Module> ] an array containing nested configuration
    # modules that inherit from ConstConf
    def nested_configurations
      nested_module_constants.map { |c|
        begin
          m = const_get(c)
        rescue NameError
          next
        end
        m.is_a?(Module) or next
        m < ConstConf or next
        m
      }.compact
    end

    # Finds a configuration setting by its environment variable name across
    # nested modules.
    #
    # This method searches through the specified modules and their nested
    # modules to locate a configuration setting that matches the given
    # environment variable name. It iterates through the module hierarchy to
    # find the setting, checking each module's settings hash for a match.
    #
    # @param name [ String, Symbol ] the environment variable name to search for
    # @param modules [ Array<Module> ] the array of modules to search within, defaults to [ self ]
    #
    # @return [ ConstConf::Setting, nil ] the matching setting object if found, or nil if not found
    def setting_for(name)
      name = name.to_s
      each_nested_configuration do |modul,|
        modul.settings.each { |env_var_name, setting|
          env_var_name == name and return setting
        }
      end
      nil
    end

    # Returns an array of all environment variable names used in the
    # configuration.
    #
    # This method collects all the environment variable names from the settings
    # defined within the current module and its nested modules. It traverses
    # the module hierarchy to gather these names, ensuring that each setting's
    # environment variable name is included in the final result.
    #
    # @return [Array<String>] an array containing all the environment variable names
    #   used in the configuration settings across the module and its nested modules
    def env_var_names
      names = Set[]
      each_nested_configuration do |modul,|
        names.merge(Array(modul.settings.keys))
      end
      names.to_a
    end

    # Returns a hash containing all environment variable values for the
    # configuration settings.
    #
    # This method collects all the environment variable names from the settings
    # defined within the current module and its nested modules, then retrieves
    # the effective value for each setting. The result is a hash where keys are
    # environment variable names and values are their corresponding
    # configuration values.
    #
    # @return [ Hash<String, Object> ] a hash mapping environment variable names to their values
    def env_vars
      env_var_names.each_with_object({}) do |n, hash|
        hash[n] = setting_value_for(n)
      end
    end

    # Retrieves the effective value for a configuration setting identified by its
    # environment variable name.
    #
    # This method looks up a configuration setting using the provided environment
    # variable name and returns its effective value, which is determined by
    # checking the environment variable and falling back to the default value if
    # not set.
    #
    # @param name [String, Symbol] the environment variable name used to identify the setting
    #
    # @return [Object] the effective configuration value for the specified setting,
    #   or the default value if the environment variable is not set
    def setting_value_for(name)
      setting = setting_for(name)
      setting&.value
    end
    alias [] setting_value_for

    # Displays a textual representation of a configuration object or setting.
    #
    # This method generates a formatted tree-like view of either a ConstConf
    # module or a specific setting, including metadata such as names,
    # descriptions, environment variable names, and configuration status. The
    # output can be directed to a specified IO object or displayed to the
    # standard output.
    #
    # @param object [Object] the ConstConf module or setting to display
    # @param io [IO, nil] the IO object to write the output to; if nil, uses STDOUT
    def view(object: self, io: nil)
      output = ConstConf::Tree.from_const_conf(object).to_a
      if io
        io.puts output
      elsif output.size < Tins::Terminal.lines
        STDOUT.puts output
      else
        IO.popen(ENV.fetch('PAGER', 'less -r'), ?w) do |f|
          f.puts output
          f.close_write
        end
      end
    end

    # Iterates over a configuration module and its nested configurations in a
    # depth-first manner.
    #
    # This method yields each configuration module, including the receiver and
    # all nested modules, in a depth-first traversal order. It is used
    # internally to process all configuration settings across a module
    # hierarchy.
    #
    # @yield [ configuration ] yields each configuration module in the hierarchy
    # @yieldparam configuration [ Module ] a configuration module from the hierarchy
    #
    # @return [ Enumerator ] returns an enumerator if no block is given,
    # otherwise nil.
    def each_nested_configuration(&block)
      return enum_for(:each_nested_configuration) unless block_given?
      configuration_modules = [ self ]
      while configuration = configuration_modules.pop
        configuration.nested_configurations.reverse_each do
          configuration_modules.member?(it) and next
          configuration_modules << it
        end
        yield configuration
      end
    end
  end
end
