module ConstConf
  # A tree structure implementation for visualizing ConstConf configuration
  # hierarchies.
  #
  # The Tree class provides a hierarchical representation of ConstConf modules
  # and settings, allowing for formatted display of configuration data with
  # metadata including prefixes, environment variable names, default values,
  # and configuration status. It supports colored output and proper indentation
  # to show the relationships between nested configuration elements.
  class Tree
    class << self
      include Term::ANSIColor

      # Converts a ConstConf configuration or setting into a tree structure for
      # display purposes.
      #
      # This method takes either a ConstConf module or a specific setting and
      # transforms it into a hierarchical tree representation that can be used
      # for visualization or debugging. It delegates to specialized conversion
      # methods based on the type of the input argument.
      #
      # @param configuration_or_setting [Object] the ConstConf module or
      # setting to convert
      #
      # @return [ConstConf::Tree] a tree object representing the configuration
      # hierarchy
      #
      # @raise [ArgumentError] if the argument is neither a ConstConf module
      # nor a ConstConf::Setting instance
      def from_const_conf(configuration_or_setting)
        if configuration?(configuration_or_setting)
          convert_module(configuration_or_setting)
        elsif configuration_or_setting.is_a?(ConstConf::Setting)
          convert_setting(configuration_or_setting)
        else
          raise ArgumentError,
            "argument needs to have type ConstConf::Setting or ConstConf"
        end
      end

      private

      # Checks whether the given object is a ConstConf module.
      #
      # This method determines if the provided object is a Module that includes
      # the ConstConf concern. It returns true if the object meets these
      # criteria, and false otherwise. In case a NameError occurs during the
      # check, it gracefully returns false.
      #
      # @param object [ Object ] the object to be checked
      #
      # @return [ Boolean ] true if the object is a ConstConf module, false
      # otherwise
      def configuration?(object)
        object.is_a?(Module) && object < ConstConf
      rescue NameError
        false
      end

      # Converts a ConstConf module into a tree-like structure for display
      # purposes.
      #
      # This method transforms a module that includes ConstConf configuration
      # settings into a hierarchical tree representation. It captures the
      # module's name, description, prefix, and number of settings, then
      # recursively processes nested modules and individual settings to build a
      # complete configuration tree.
      #
      # @param modul [Module] the ConstConf module to convert into a tree
      # structure
      # @return [ConstConf::Tree] a tree object representing the module's
      # configuration hierarchy
      def convert_module(modul)
        desc = "#{modul.description.full? { italic(' # %s' % it) }}"
        obj  = new("#{modul.name}#{desc}")
        obj << new("prefix #{modul.prefix.inspect}")
        obj << new("#{modul.settings.size} settings")

        modul.settings.each do |env_var, setting|
          obj << convert_setting(setting)
        end

        modul.constants.sort.each do |const_name|
          begin
            const = modul.const_get(const_name)
            if const.is_a?(Module) && const < ConstConf
              obj << convert_module(const)
            end
          rescue NameError
          end
        end

        obj
      end

      # Converts a configuration setting into a tree node with detailed
      # information.
      #
      # This method transforms a given configuration setting into a
      # hierarchical representation, including its name, description, and
      # various metadata such as environment variable name, prefix, default
      # value, and configuration status.
      #
      # @param setting [ConstConf::Setting] the configuration setting to convert
      #
      # @return [ConstConf::Tree] a tree node representing the configuration setting
      def convert_setting(setting)
        desc = "#{setting.description.full? { italic(' # %s' % it) }}"
        obj  = new("#{bold(setting.name)}#{desc}")

        length = (Tins::Terminal.columns / 4).clamp(20..)
        truncater = -> v { v&.to_s&.truncate_bytes(length) }

        censored = -> s { s.sensitive? ? Tins::NullPlus.new(inspect: '🤫') : s }

        checker = -> r {
          case r
          when false, nil
            '❌'
          when :unchecked_true
            '☑️ '
          else
            '✅'
          end
        }

        setting_info = <<~EOT
          prefix          #{setting.prefix.inspect}
          env var name    #{setting.env_var_name}
          env var (orig.) #{truncater.(censored.(setting).env_var.inspect)}
          default         #{truncater.(censored.(setting).default_value.inspect)}
          value           #{truncater.(censored.(setting).value.inspect)}
          sensitive       #{setting.sensitive? ? '🔒' : '⚪'}
          required        #{setting.required? ? '🔴' : '⚪'}
          configured      #{setting.configured? ? '🔧' : '⚪' }
          ignored         #{setting.ignored? ? '🙈' : '⚪'}
          active          #{setting.active? ? '🟢' : '⚪'}
          decoding        #{setting.decoding? ? '⚙️' : '⚪'}
          checked         #{checker.(setting.checked?)}
        EOT

        setting_info.each_line do |line|
          obj << new(line.chomp)
        end

        obj
      end
    end

    # Initializes a new tree node with the given name, and UTF-8 support
    # flag.
    #
    # @param name [ String ] the name of the tree node
    # @param utf8 [ Boolean ] flag indicating whether UTF-8 characters should
    # be used for display
    def initialize(name, utf8: default_utf8)
      @name     = name
      @utf8     = utf8
      @children = []
    end

    # Checks whether UTF-8 encoding is indicated in the LANG environment
    # variable.
    #
    # This method examines the LANG environment variable to determine if it
    # contains a UTF-8 encoding indicator, returning true if UTF-8 is detected
    # and false otherwise.
    #
    # @return [Boolean] true if the LANG environment variable indicates UTF-8
    # encoding, false otherwise
    def default_utf8
      !!(ENV['LANG'] =~ /utf-8\z/i)
    end

    # Adds a child node to this tree node's collection of children.
    #
    # @param child [ ConstConf::Tree ] the child tree node to be added
    #
    # @return [ Array<ConstConf::Tree> ] the updated array of child nodes
    def <<(child)
      @children << child
    end

    # Returns an enumerator that yields the tree node's name,
    # followed by its children in a hierarchical format.
    #
    # @return [Enumerator] an enumerator that provides the tree structure
    #   as a sequence of strings representing nodes and their relationships
    def to_enum
      Enumerator.new do |y|
        y.yield @name

        @children.each_with_index do |child, child_index|
          children_enum = child.to_enum
          if child_index < @children.size - 1
            children_enum.each_with_index do |setting, i|
              y.yield "#{inner_child_prefix(i)}#{setting}"
            end
          else
            children_enum.each_with_index do |setting, i|
              y.yield "#{last_child_prefix(i)}#{setting}"
            end
          end
        end
      end
    end

    # Converts the tree node into an array representation.
    #
    # @return [Array<String>] an array containing the string representations of
    # the tree node and its children
    def to_ary
      to_enum.to_a
    end

    alias to_a to_ary

    # Returns the string representation of the tree structure.
    #
    # This method converts the tree node and its children into a formatted
    # string, where each node is represented on its own line with appropriate
    # indentation to show the hierarchical relationship between nodes.
    #
    # @return [String] a multi-line string representation of the tree structure
    def to_s
      to_ary * ?\n
    end

    private

    # Returns the appropriate prefix string for a child node in a tree display.
    #
    # This method determines the correct visual prefix to use when rendering
    # tree nodes, based on whether UTF-8 encoding is enabled and if the current
    # child is the first one in a group of siblings.
    #
    # @param i [ Integer ] the index of the child node in its parent's children list
    # @return [ String ] the visual prefix string for the child node
    def inner_child_prefix(i)
      if @utf8
        i.zero? ? "├─ " : "│  "
      else
        i.zero? ? "+- " : "|  "
      end
    end

    # Returns the appropriate prefix string for the last child node in a tree
    # display.
    #
    # This method determines the correct visual prefix to use when rendering
    # the final child node in a hierarchical tree structure, based on whether
    # UTF-8 encoding is enabled and if the current child is the first one in a
    # group of siblings.
    #
    # @param i [Integer] the index of the child node in its parent's children list
    # @return [String] the visual prefix string for the last child node
    def last_child_prefix(i)
      if @utf8
        i.zero? ? "└─ " : "   "
      else
        i.zero? ? "`- " : "   "
      end
    end
  end
end
