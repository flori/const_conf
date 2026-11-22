# Changes

## 2026-11-18 v0.11.0

### Improvements
- Replaced `require 'json'` with `require 'json/generic_object'` in
  `JSONPlugin` to ensure `JSON::GenericObject` is available for the
  `JSONConfig` inheritance chain.

### Build & CI
- Added `json-generic_object` as a runtime dependency.
- Updated `context_spook` development dependency from `~> 0.4` to
  `~> 1.8`.

## 2026-11-18 v0.10.0

### Improvements
- Relaxed the `json` runtime dependency constraint from `~> 2.0` to
  `>= 2.0`, `< 4` to allow compatibility with `json` 3.x.
- Removed Vim modeline comments from `Gemfile` and `Rakefile`.

### Build & CI
- Bumped the `gem_hadar` development dependency requirement to
  `>= 2.24.1`.

### Documentation
- Refactored `.contexts/yard.md` to define the AI's role as generating
  only YARD documentation comments.
- Introduced a comprehensive `Document` class example demonstrating usage
  of `@example`, `@!attribute`, `@param`, `@option`, `@yieldparam`,
  `@yieldreturn`, `@overload`, `@deprecated`, and `@see` tags.
- Established key rules prohibiting executable code and `@return [void]`
  clauses.
- Replaced previous cheatsheet sections for modules, classes, methods,
  and blocks with structured documentation responsibilities.

## 2026-10-01 v0.9.0

### Features
- Add `pager:` keyword argument to `ConstConf.view` and
  `Setting#view`, allowing callers to override the pager command
  for long output; defaults to `ENV['PAGER']` or `less -r`

### Documentation
- Add YARD `@param pager` documentation to both `view` methods

### Testing
- Add spec verifying that a custom `pager:` string is passed
  through to `IO.popen`

## 2026-08-20 v0.8.2

### Documentation
- Documented block calling contexts for `decode`, `required`, and
  `check` in the README, clarifying `Proc` calls versus
  `instance_eval`.
- Added a YARD note to `ConstConf::Setting#checked?` explaining
  unconditional evaluation in `ConstConf::Setting#confirm!`.
- Updated YARD documentation for `ConstConf::Setting#check` to clarify
  `instance_eval` arity rules and correct typos.
- Rewrote the `?` predicate section to explain the `FOO::BAR`
  constant and `FOO::BAR?` predicate access pattern.
- Added a "How concepts compose" section with a scenario table for
  `confirm!`, constants, and predicates.
- Clarified the distinction between `required` and blank values in
  the README and `ConstConf::Setting#confirm!` documentation.
- Corrected guidance for guarding absent values to use
  `value.blank?` instead of `value.nil?`.
- Fixed a typo in the README truthy value description.
- Clarified that `sensitive` masks values in `view` output.

### Build & CI
- Added emoji-based status messages and descriptive cleanup steps to
  test scripts.

## 2026-08-04 v0.8.1

### Fixes
- Replaced the `nil?` check with `blank?` in `lib/const_conf/json_plugin.rb`
  to ensure the JSON decoder correctly handles empty or whitespace-only
  input strings.

### Testing
- Added test cases in `spec/const_conf/json_plugin_spec.rb` to verify
  that empty and whitespace-only input values return `nil`.

## 2026-07-20 v0.8.0

### Breaking
- `ConstConf::JSONPlugin#json` now requires a path argument to load a file
  and returns a lambda when called without arguments.

### Features
- `ConstConf::JSONPlugin#json` now functions as a decoder factory, returning
  a lambda for parsing JSON strings from environment variables.
- Introduced `ConstConf::JSONPlugin::JSONConfig` to prevent arbitrary class
  materialization by stripping `'json_class'` during serialization.

### Fixes
- Corrected documentation assertions in `spec/const_conf_spec.rb` to match the
  updated header `"## ConstConf settings via environment variables"`.

### Improvements
- Reorganized tests in `spec/const_conf/json_plugin_spec.rb` into file and
  string contexts to verify the new `#json` API.
- Updated `README.md` to document the dual-mode behavior of `JSONPlugin`.

### Build & CI
- Updated `simplecov` dependency to **1.0**.
- Updated `gem_hadar` requirement to **2.17.1**.
- Updated `rubygems_version` to **4.0.16** in `const_conf.gemspec`.

### Documentation
- Added "Automating Configuration Documentation" section to `README.md` with
  examples for a Rake task and a Git pre-commit hook.

## 2026-01-28 v0.7.0

### Improvements
- Changed the `documentation` method header to read "ConstConf settings via environment variables"
- Updated `documentation` to display `name` instead of `env_var_name` for
  hierarchical setting names
- Added a `__variable__` field to the `documentation` output showing the
  actual environment variable names

## 2026-01-27 v0.6.0

### Features
- Added `documentation` method to the `ConstConf` module that
  generates Markdown documentation for configuration settings.
- The new `documentation` method supports both string return and IO
  writing modes via the `io:` parameter.
- Sensitive configuration values are redacted as `_redacted_` in the
  generated documentation output.
- `nil` default values are displayed as `_undefined_` in the generated
  documentation output.

### Improvements
- Simplified the environment variable handling logic in `configured_value`.

### Build & CI
- Updated the `all_images` development dependency requirement from **0.8**
  to **>= 0.12**.
- Updated the `gem_hadar` development dependency requirement from
  **2.16.3** to **>= 2.17.0**.
- Updated the CI configuration to use `bundle exec rake spec` and added
  `before` and `after` hooks to manage `Gemfile.lock`.
- Updated the Ruby version in the test matrix from `4.0-rc-alpine` to
  `4.0-alpine`.
- Added `changelog` configuration to the GemHadar setup to manage
  `CHANGES.md`.

## 2025-12-19 v0.5.0

### Build & CI
- Broadened required `ruby` version from `~> 3.2` to `>= 3.2` in
  `Rakefile` and `const_conf.gemspec`.
- Updated `rubygems` version in `const_conf.gemspec` from **3.7.2**
  to **4.0.2**.

### Testing
- Added `ruby:4.0-rc-alpine` image to the test matrix in
  `.all_images.yml`.
- Changed `bundle update` to `bundle update --all` in
  `.all_images.yml`.

## 2025-10-30 v0.4.3

### Features

- Add `term/ansicolor` dependency for colored terminal output.

## 2025-10-29 v0.4.2

### Features
- Added `require 'pathname'` to enable path manipulation functionality in the constant configuration.

### Build & CI
- Updated `s.rubygems_version` in the gemspec from **3.6.9** to **3.7.2**.

## 2025-10-15 v0.4.1

### Build & CI
- Added `.github/workflows/static.yml` to deploy static content and
  documentation to GitHub Pages using Ruby **3.4**.
- Updated `Rakefile` to ignore the `.github` directory and register GitHub
  workflows configuration.
- Added `openssl-dev` to the apk add command in the Dockerfile.

### Documentation
- Updated `README.md` to include a link to the GitHub.io documentation.

## 2025-09-18 v0.4.0

### Features
- Added a `strip: false` parameter to the `file` method in
  `ConstConf::FilePlugin` to allow automatic removal of leading and
  trailing whitespace from configuration file contents when `strip: true`
  is specified.

### Build & CI
- Downgraded the `simplecov` development dependency version from **0.23**
  to **0.22** in both the `Rakefile` and the gemspec to ensure consistent
  coverage reporting environments.

## 2025-09-18 v0.3.1

### Fixes
- Fixed prefix calculation in nested modules by using
  `ask_and_send(:prefix)` to robustly detect the prefix when
  using `ConstConf` in nested module contexts.

### Improvements
- Replaced `require 'rails'` with `require 'active_support/all'`
  to reduce dependency size.
- Updated `tins` dependency from **1.42** to **1.43**.
- Updated `complex_config` dependency from **0.22** to **0.23**.
- Relaxed Ruby version requirement from `= 3.2` to `~> 3.2` to
  support Ruby 3.2.x releases.

### Build & CI
- Added Ruby version constraint of **3.2** to the gemspec and
  `Rakefile`.
- Updated `Dockerfile` configuration to install `bundler` and
  `gem_hadar` directly and changed the test command from
  `rake test` to `rake spec`.
- Added `fail_fast: true` to the CI configuration.
- Added support for Ruby **3.3** and **3.2** Alpine images in the
  CI pipeline.

### Documentation
- Added `color:#07f` to diagram node styles in `README.md` to
  improve text visibility on colored backgrounds.

## 2025-09-13 v0.2.2

### Improvements
- Simplified ignore patterns in the `Rakefile` by replacing
  `*.contexts/*` with `.contexts` and removing `.github`

### Build & CI
- Updated the `gem_hadar` dependency requirement from `~> **2.2**` to
  `~> **2.6**` in the gemspec

### Documentation
- Added documentation for getter methods with exclamation marks

## 2025-09-07 v0.2.1

### Fixes
- Removed explicit boolean coercion applied to test values in predicate
  methods within `ConstConf::ConstConfHelper`.

## 2025-09-07 v0.2.0

### Features
- Added `ConstConf::ConstConfHelper` module with a `const_conf_as` method
  for overriding constant values and predicate methods during testing.

### Documentation
- Added a new testing chapter to `README.md` documenting the `const_conf_as`
  helper for RSpec.
- Added a `CHANGES.md` file containing the project's release history.
- Reformatted long comment lines in source files to improve readability.

## 2025-09-02 v0.1.2

### Improvements
- Applied bold formatting to the `value` field in the `ConstConf::Tree`
  output for improved visual distinction.

## 2025-09-01 v0.1.1

### Improvements
- Replaced the `rails` dependency with a more precise dependency
  on `activesupport` version **8**.
- Made the loading of `const_conf/railtie` conditional on
  `Rails::Railtie` being defined, enabling usage in non-Rails
  applications.

## 2025-08-30 v0.1.0

### Fixes
- Fixed nested configuration ordering and tracking consistency by replacing
  `constants.map` with `nested_module_constants.map` and updating the
  `each_nested_configuration` logic to perform a depth-first traversal.
- Added a `nested_module_constants` tracking set to maintain definition order
  and implemented a `remove_const` override to keep the tracking consistent.
- Updated the tree display to use `nested_module_constants` instead of
  `constants.sort`.

### Improvements
- Added comprehensive documentation and improved the implementations of the
  `json` and `yaml` plugins.

### Testing
- Added comprehensive tests for nested configuration ordering and
  `remove_const` functionality.

### Build & CI
- Updated the `gem_hadar` development dependency from version **2.1** to
  **2.2**.
- Added `.starscope.db` and `cscope.out` to the ignore list in `.gitignore`
  and `Rakefile`.

## 2025-08-28 v0.0.0

  * Start
