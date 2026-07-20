require 'json'

# A module that provides functionality for loading JSON files or parsing
# JSON strings as configuration values.
#
# The JSONPlugin module extends the ConstConf::Setting class to enable
# configuration settings that are either sourced from JSON files on disk
# or decoded from JSON-formatted environment variables. It ensures a stable,
# polymorphic representation by using the {ConstConf::JSONPlugin::JSONConfig}
# class for all parsed objects.
module ConstConf::JSONPlugin
  # JSONConfig - Custom JSON object class for config values
  #
  # Rejects 'json_class' during serialization to prevent forcing concrete
  # class re-materialization on deserialization. Useful for polymorphic
  # configuration handling.
  class JSONConfig < JSON::GenericObject
    # as_json - Serialize hash without metadata keys
    # @return [Hash] Hash representation excluding json_class keys
    def as_json(*a)
      super.reject { _1 == 'json_class' }
    end
  end

  # Provides JSON loading or decoding logic based on the presence of a path.
  #
  # === As a Loader (Path provided)
  # When a +path+ is given, it reads the file from the filesystem and parses
  # its content into a {JSONConfig} object.
  #
  # === As a Factory (No path provided)
  # When called without arguments, it returns a Proc that can be used in
  # a +decode+ block to parse JSON strings (e.g., from environment variables).
  #
  # @param path [String, nil] the filesystem path to the JSON file; if omitted,
  #   a decoder Proc is returned instead.
  # @param required [Boolean] whether the file must exist (only applicable
  #   when +path+ is provided), defaults to false.
  # @param object_class [Class] the class used for parsing JSON objects,
  #   defaults to {ConstConf::JSONPlugin::JSONConfig}.
  #
  # @return [JSONConfig, Proc, nil] returns a parsed {JSONConfig} (or nil if
  #   missing and not required) when +path+ is provided; otherwise, returns a
  #   Proc for decoding.
  #
  # @raise [ConstConf::RequiredValueNotConfigured] if the file does not exist
  #   and +required+ is true.
  def json(path = nil, required: false, object_class: JSONConfig)
    if path
      if File.exist?(path)
        JSON.load_file(path, object_class:)
      elsif required
        raise ConstConf::RequiredValueNotConfigured,
          "JSON file required at path #{path.to_s.inspect}"
      end
    else
      -> value { JSON.parse(value, object_class:) unless value.nil? }
    end
  end
end
