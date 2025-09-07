# Changes

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
