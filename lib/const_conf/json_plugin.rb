require 'json'

module ConstConf::JSONPlugin
  def json(path, required: false, object_class: JSON::GenericObject)
    if File.exist?(path)
      JSON.load_file(path, object_class:)
    elsif required
      raise ConstConf::RequiredValueNotConfigured,
        "JSON file required at path #{path.to_s.inspect}"
    end
  end
end
