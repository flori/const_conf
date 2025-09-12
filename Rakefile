# vim: set filetype=ruby et sw=2 ts=2:

require 'gem_hadar'

GemHadar do
  name        'const_conf'
  module_type :module
  author      'Florian Frank'
  email       'flori@ping.de'
  homepage    'https://github.com/flori/const_conf'
  summary     'Clean DSL for config settings with validation and Rails integration'
  description  <<~EOT
    ConstConf is a Ruby configuration library that manages settings
    through environment variables, files, and directories with comprehensive
    validation and Rails integration.
  EOT
  test_dir    'spec'
  ignore      '.*.sw[pon]', 'pkg', 'Gemfile.lock', '.AppleDouble', '.bundle',
    '.yardoc', 'doc', 'tags', 'coverage', 'cscope.out', '.starscope.db'
  package_ignore '.all_images.yml', '.gitignore', 'VERSION', '.utilsrc',
    '.contexts'
  readme      'README.md'

  dependency 'tins',           '~> 1.42'
  dependency 'json',           '~> 2.0'
  dependency 'complex_config', '~> 0.22'
  dependency 'activesupport',  '~> 8'
  development_dependency 'debug'
  development_dependency 'rspec',         '~> 3.13'
  development_dependency 'context_spook', '~> 0.3'
  development_dependency 'all_images',    '~> 0.6'
  development_dependency 'simplecov',     '~> 0.22'

  licenses << 'MIT'
end
