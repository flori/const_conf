require 'complex_config'

module ConstConf::YAMLPlugin
  include ComplexConfig::Provider::Shortcuts

  def yaml(path, required: false, env: false)
    if File.exist?(path)
      ConstConf.monitor.synchronize do
        config_dir = File.dirname(path)
        ComplexConfig::Provider.config_dir = config_dir
        ext        = File.extname(path)
        name       = File.basename(path, ext)
        if env
          env == true and env = ENV['RAILS_ENV']
          if env
            complex_config_with_env(name, env)
          else
            raise ConstConf::RequiredValueNotConfigured,
              "need an environment string specified, via env var RAILS_ENV or manually"
          end
        else
          complex_config(name)
        end
      end
    elsif required
      raise ConstConf::RequiredValueNotConfigured,
        "YAML file required at path #{path.to_s.inspect}"
    end
  end
end
