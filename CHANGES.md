# Changes

## 2025-09-18 v0.3.0

- Replaced `require 'rails'` with `require 'active_support/all'` to reduce
  dependency size
- Updated `tins` dependency from version **1.42** to **1.43**
- Updated `complex_config` dependency from version **0.22** to **0.23**
- Updated development dependencies: `context_spook` from **0.3** to **0.4**,
  `all_images` from **0.6** to **0.8**, and `simplecov` from **0.22** to
  **0.23**
- Added required Ruby version constraint of **= 3.2**
- Replaced `it` with `_1` in block parameters for Ruby **3.2** compatibility
- Updated Dockerfile to install `bundler` and `gem_hadar` gems directly
- Changed test command from `rake test` to `rake spec`
- Added `fail_fast: true` to CI configuration
- Added support for Ruby **3.3** and **3.2** Alpine images in CI pipeline
- Fixed prefix computation in nested modules with
- Added `color:#07f` to all diagram node style definitions in `README.md` to
  improve text visibility on colored backgrounds

## 2025-09-13 v0.2.2

- Simplified ignore patterns in `Rakefile` by changing `*.contexts/*` to
  `.contexts`
- Removed `.github` from ignored patterns in `Rakefile`
- Updated `gem_hadar` dependency from ~> **2.2** to ~> **2.6** in gemspec
- Added documentation for getter methods with exclamation mark

## 2025-09-07 v0.2.1

- Removed explicit boolean coercion previously applied to test values in
  predicate methods

## 2025-09-07 v0.2.0

- Implemented `ConstConf::ConstConfHelper` module in
  `lib/const_conf/spec/const_conf_helper.rb`
- Added comprehensive testing chapter to README.md explaining usage of
  `const_conf_as` helper
- Helper supports nested module constants and predicate method mocking
- Created `lib/const_conf/spec.rb` require file for testing utilities

## 2025-09-02 v0.1.2

- Added bold formatting to value display in tree output

## 2025-09-01 v0.1.1

- Enables usage in both Rails and non-Rails applications
- Maintains Rails integration when Rails is present
- Uses more precise dependency on Active Support rather than full Rails
  framework

## 2025-08-30 v0.1.0

- Added `nested_module_constants` tracking set to maintain definition order
- Updated `each_nested_configuration` to use depth-first search (DFS) with
  correct ordering
- Implemented override for `remove_const` method to keep tracking consistent
- Added comprehensive tests for nested configuration ordering
- Updated tree display implementation to use `nested_module_constants` instead
  of `constants.sort`
- Added comprehensive documentation and improved JSON/YAML plugin
  implementations

## 2025-08-28 v0.0.0

  * Start
