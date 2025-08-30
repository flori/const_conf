# -*- encoding: utf-8 -*-
# stub: const_conf 0.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "const_conf".freeze
  s.version = "0.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Florian Frank".freeze]
  s.date = "1980-01-02"
  s.description = "ConstConf is a Ruby configuration library that manages settings\nthrough environment variables, files, and directories with comprehensive\nvalidation and Rails integration.\n".freeze
  s.email = "flori@ping.de".freeze
  s.extra_rdoc_files = ["README.md".freeze, "lib/const_conf.rb".freeze, "lib/const_conf/dir_plugin.rb".freeze, "lib/const_conf/env_dir_extension.rb".freeze, "lib/const_conf/errors.rb".freeze, "lib/const_conf/file_plugin.rb".freeze, "lib/const_conf/json_plugin.rb".freeze, "lib/const_conf/railtie.rb".freeze, "lib/const_conf/setting.rb".freeze, "lib/const_conf/setting_accessor.rb".freeze, "lib/const_conf/tree.rb".freeze, "lib/const_conf/version.rb".freeze, "lib/const_conf/yaml_plugin.rb".freeze]
  s.files = ["Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "const_conf.gemspec".freeze, "lib/const_conf.rb".freeze, "lib/const_conf/dir_plugin.rb".freeze, "lib/const_conf/env_dir_extension.rb".freeze, "lib/const_conf/errors.rb".freeze, "lib/const_conf/file_plugin.rb".freeze, "lib/const_conf/json_plugin.rb".freeze, "lib/const_conf/railtie.rb".freeze, "lib/const_conf/setting.rb".freeze, "lib/const_conf/setting_accessor.rb".freeze, "lib/const_conf/tree.rb".freeze, "lib/const_conf/version.rb".freeze, "lib/const_conf/yaml_plugin.rb".freeze, "spec/assets/.env/API_KEY".freeze, "spec/assets/config.json".freeze, "spec/assets/config.yml".freeze, "spec/assets/config_env.yml".freeze, "spec/const_conf/dir_plugin_spec.rb".freeze, "spec/const_conf/env_dir_extension_spec.rb".freeze, "spec/const_conf/file_plugin_spec.rb".freeze, "spec/const_conf/json_plugin_spec.rb".freeze, "spec/const_conf/setting_accessor_spec.rb".freeze, "spec/const_conf/setting_spec.rb".freeze, "spec/const_conf/tree_spec.rb".freeze, "spec/const_conf/yaml_plugin_spec.rb".freeze, "spec/const_conf_spec.rb".freeze, "spec/spec_helper.rb".freeze]
  s.homepage = "https://github.com/flori/const_conf".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--title".freeze, "ConstConf - Clean DSL for config settings with validation and Rails integration".freeze, "--main".freeze, "README.md".freeze]
  s.rubygems_version = "3.6.9".freeze
  s.summary = "Clean DSL for config settings with validation and Rails integration".freeze
  s.test_files = ["spec/const_conf/dir_plugin_spec.rb".freeze, "spec/const_conf/env_dir_extension_spec.rb".freeze, "spec/const_conf/file_plugin_spec.rb".freeze, "spec/const_conf/json_plugin_spec.rb".freeze, "spec/const_conf/setting_accessor_spec.rb".freeze, "spec/const_conf/setting_spec.rb".freeze, "spec/const_conf/tree_spec.rb".freeze, "spec/const_conf/yaml_plugin_spec.rb".freeze, "spec/const_conf_spec.rb".freeze, "spec/spec_helper.rb".freeze]

  s.specification_version = 4

  s.add_development_dependency(%q<gem_hadar>.freeze, ["~> 2.2".freeze])
  s.add_development_dependency(%q<debug>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.13".freeze])
  s.add_development_dependency(%q<context_spook>.freeze, ["~> 0.3".freeze])
  s.add_development_dependency(%q<all_images>.freeze, ["~> 0.6".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.22".freeze])
  s.add_runtime_dependency(%q<tins>.freeze, ["~> 1.42".freeze])
  s.add_runtime_dependency(%q<rails>.freeze, ["~> 8".freeze])
  s.add_runtime_dependency(%q<json>.freeze, ["~> 2.0".freeze])
  s.add_runtime_dependency(%q<complex_config>.freeze, ["~> 0.22".freeze])
end
