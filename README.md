# ConstConf

**ConstConf**: A robust, thread-safe configuration management library for Ruby
applications.

## Documentation

Complete API documentation is available at: [GitHub.io](https://flori.github.io/const_conf/)

## Description

ConstConf provides a clean DSL for defining configuration settings with
environment variable support, default values, required validation, decoding
logic, and descriptive metadata. It offers file-based configuration plugins,
XDG Base Directory Specification compliance, and seamless Rails integration.

## Installation

To install ConstConf, you can use the following methods:

1. Type

```shell
gem install const_conf
```

in your terminal.

1. Or add the line

```ruby
gem 'const_conf'
```

to your Gemfile and run `bundle install` in your terminal.

## Usage

Define configuration in a module:

```ruby
require 'const_conf'

module AppConfig
  include ConstConf

  plugin ConstConf::FilePlugin # Use FilePlugin
  plugin ConstConf::DirPlugin  # Use DirPlugin

  description 'Application Configuration'
  prefix '' # Use empty prefix for flat environment variable names

  # Simple environment variable setting
  DATABASE_URL = set do
    description 'Database connection string'
    required true
    sensitive true
  end

  # File-based configuration
  API_KEY = set do
    prefix 'CONFIG'
    description 'API key from file'
    default file('config/api.key', required: true)
    sensitive true
    decode(&:chomp)
  end

  # Directory-based configuration with XDG support
  CONFIG_FROM_DIR = set do
    description 'Configuration directory path'
    default dir('myapp', 'config.yaml', env_var_name: 'XDG_CONFIG_HOME')
    decode { require 'yaml'; YAML.load(it) }
  end
end

# Access settings
puts AppConfig::DATABASE_URL     # From ENV['DATABASE_URL']
puts AppConfig::API_KEY          # Default file config/api.key, or ENV['CONFIG_API_KEY']
puts AppConfig::CONFIG_FROM_DIR  # From directory structure at ENV['XDG_CONFIG_HOME'] + "/myapp"
# =>
# postgresql://user:pass@localhost/myapp
# sk-1234567890abcdef1234567890abcdef
# {"host" => "localhost", "port" => 3000}
```

In Rails it is best to require your configuration in `config/app_config.rb` as soon
as the bundled gems were loaded, so subsequent initiallizers can access the
created setting constants:
init
```ruby
Bundler.require(*Rails.groups)
require_relative 'app_config.rb'

module MyApp
…
end
```

### Note that **Predicate Methods (`?`)** are defined

If a setting is `active?`, the predicate method returns a truthy value, which
then can be used like this:

```ruby
# Check if active?
if database_url = AppConfig::DATABASE_URL?
  connect_to_database with: database_url
else
  STDERR.puts "No DATABASE_URL configured for app!"
end
```

Or `nil` is returned, which can then be handled accordingly.

### Note that **Getter Methods (`!`)** are also defined

In addition to predicate methods, ConstConf automatically defines `!` methods
that return the actual `ConstConf::Setting` object. These are useful for:

- Accessing setting metadata and properties directly
- Calling methods like `setting.view` for detailed configuration inspection of
  a single setting.
- Testing specific setting characteristics beyond just their values

For example:

```ruby
# Returns the Setting object itself
db_setting = AppConfig::DATABASE_URL!

# Useful for debugging/inspection
db_setting.view  # Shows detailed configuration information

# Access setting properties directly
puts db_setting.description
puts db_setting.required?
puts db_setting.sensitive?
```

This complements the `?` methods which return the actual configuration value
when active, while the `!` methods provide access to the setting object for
more advanced use cases.

### Configuration View Explanation

The `AppConfig.view` output shows the complete configuration hierarchy with
detailed metadata for each setting. Sensitive values are displayed as 🤫 to
protect confidential information like passwords and API keys.

Key indicators in the view:


| Yes | No | Purpose |
|:---:|:---:|----------------------|
| 🔒  | ⚪  | Sensitive data (e.g., passwords, tokens)|
| 🤫  | …   | Suppressed output of value if sensitive|
| 🔴  | ⚪  | Required settings that must be configured|
| 🔧  | ⚪  | Configured values from ENV |
| 🙈  | ⚪  | ENV var was ignored |
| 🟢  | ⚪  | Setting is active (? method returns truty value) |
| ⚙️   | ⚪  | Decoding logic applied to transform raw input |
| ✅  ┊ ☑️   | ❌ | Validation checks have passed or failed |

The view helps developers understand how configuration is resolved from
multiple sources and validate that settings are properly configured while
protecting sensitive data.

```
AppConfig # Application Configuration
├─ prefix ""
├─ 3 settings
├─ AppConfig::DATABASE_URL # Database connection string
│  ├─ prefix          ""
│  ├─ env var name    DATABASE_URL
│  ├─ env var (orig.) 🤫
│  ├─ default         🤫
│  ├─ value           🤫
│  ├─ sensitive       🔒
│  ├─ required        🔴
│  ├─ configured      🔧
│  ├─ ignored         ⚪
│  ├─ active          🟢
│  ├─ decoding        ⚪
│  └─ checked         ☑️
├─ AppConfig::API_KEY # API key from file
│  ├─ prefix          "CONFIG"
│  ├─ env var name    CONFIG_API_KEY
│  ├─ env var (orig.) 🤫
│  ├─ default         🤫
│  ├─ value           🤫
│  ├─ sensitive       🔒
│  ├─ required        ⚪
│  ├─ configured      ⚪
│  ├─ ignored         ⚪
│  ├─ active          🟢
│  ├─ decoding        ⚙️
│  └─ checked         ☑️
└─ AppConfig::CONFIG_FROM_DIR # Configuration directory path
   ├─ prefix          ""
   ├─ env var name    CONFIG_FROM_DIR
   ├─ env var (orig.) nil
   ├─ default         "host: 'localhost'\nport: 3000\n"
   ├─ value           {"host" => "localhost", "port" => 3000}
   ├─ sensitive       ⚪
   ├─ required        ⚪
   ├─ configured      ⚪
   ├─ ignored         ⚪
   ├─ active          🟢
   ├─ decoding        ⚙️
   └─ checked         ☑️

```

### Use of Plugins

ConstConf provides extensible plugin architecture for adding configuration
sources and behaviors, as can be seen in the example above. The library
includes two main built-in plugins:

```mermaid
graph TD
    A[ConstConf Module] --> B[set do Block]
    A --> C[Plugin System]

    C --> D[FilePlugin]
    C --> E[DirPlugin]
    C --> F[JSONPlugin]
    C --> G[YAMLPlugin]
    C --> H[Custom Plugins]

    B --> I[DSL Methods]
    I --> J[file method]
    I --> K[dir method]
    I --> L[json method]
    I --> M[yaml method]
    I --> N[Core DSL methods]

    D --> O[File-based Configuration]
    E --> P[Directory-based Configuration]
    F --> Q[JSON Configuration]
    G --> R[YAML Configuration]
    H --> S[Custom Configuration Sources]

    O --> T[File Reading Logic]
    P --> U[Directory Traversal Logic]
    Q --> V[JSON Parsing Logic]
    R --> W[YAML Parsing Logic]
    S --> X[Custom Logic]

    I --> Y[Configuration Resolution Process]
    Y --> Z[ENV Variable Lookup]
    Y --> AA[Default Value Handling]
    Y --> AB[Validation & Processing]

    style A fill:#e1f5fe;color:#07f
    style B fill:#f3e5f5;color:#07f
    style C fill:#e8f5e9;color:#07f
    style D fill:#fff3e0;color:#07f
    style E fill:#fce4ec;color:#07f
    style F fill:#f1f8e9;color:#07f
    style G fill:#e0f2f1;color:#07f
    style H fill:#f1f8e9;color:#07f
    style I fill:#fafafa;color:#07f
    style Y fill:#ffebee;color:#07f
```

#### FilePlugin

Enables file-based configuration through the `file()` method:

```ruby
API_KEY = set do
  default file('config/api.key', required: true)
  …
end
```

#### DirPlugin

Enables directory-based configuration with XDG compliance through the `dir()`
method:

```ruby
CONFIG_FROM_DIR = set do
  default dir('myapp', 'config.yaml', env_var_name: 'XDG_CONFIG_HOME')
  …
end
```

#### JSONPlugin

Enables JSON-based configuration through the `json()` method:

```ruby
CONFIG = set do
  default json('config.json')
  # or with custom object class:
  # default json('config.json', object_class: MyCustomClass)
  …
end
```

#### YAMLPlugin

Enables YAML-based configuration through the `yaml()` method:

```ruby
CONFIG = set do
  default yaml('config.yaml')
  # or with environment-specific loading:
  # default yaml('config.yaml', env: true)
  # or with explicit environment:
  # default yaml('config.yaml', env: 'production')
  …
end
```

Plugins are registered using the `plugin` method at the module level. Multiple
plugins can be combined to provide flexible configuration sources.

When a plugin is loaded, it extends the DSL with additional methods and
behaviors that can be used within `set do` blocks. The plugin system allows for
easy extension of ConstConf's capabilities without modifying core
functionality.

### Configuration Concepts Explained

#### **Description**

- **Purpose**: Human-readable explanation of what the setting is for (📝 is
  always required to be provided)
- **Implementation**: The `description` accessor stores a string explaining the
  setting's purpose
- **Usage**: `description 'Database connection string'`
- **Indicator**: Shows in view output as descriptive text next to each setting

#### **Prefix**

- **Purpose**: Namespace prefix used to construct environment variable names
- **Implementation**: The `prefix` accessor determines how environment
  variables are named
- **Usage**: `prefix 'APP'` makes `API_KEY` become `APP_API_KEY`
- **Indicator**: Shows as prefix value in view output

#### **Decoding** (`decoding?`)

- **Purpose**: Transforms raw input values using a Proc
- **Implementation**: The `decode` accessor stores a Proc that processes the
  value
- **Usage**: `decode(&:chomp)` removes whitespace, `decode { YAML.load(it) }`
  parses YAML
- **Indicator**: Shows ⚙️ in view output when active

#### **Required** (`required?`)

- **Purpose**: Determines if a setting must have a valid value
- **Implementation**: Can be boolean (`true/false`) or Proc for conditional
  validation
- **Usage**: `required true` (always required) or `required { !Rails.env.test?
  }` (conditional)
- **Indicator**: Shows 🔴 in view output when required and not satisfied

#### **Configured** (`configured?`)

- **Purpose**: Indicates whether a value was actually provided (not just
  default)
- **Implementation**: Checks if environment variable is set or default is used
- **Usage**: `configured?` returns true when `ENV['VAR_NAME']` exists or
  default is non-nil
- **Indicator**: Shows 🔧 in view output when value is explicitly provided

#### **Checked** (`checked?`)

- **Purpose**: Validates that custom validation logic passes
- **Implementation**: The `check` accessor stores validation logic as Proc
- **Usage**: `check ->(setting) { setting.value >= 1024 }` for port validation
- **Indicator Logic**:
  - **☑️** = No custom check defined (passes by default - `:unchecked_true`)
  - **✅** = Custom check explicitly passes (returns `true`)
  - **❌** = Custom check explicitly fails (returns `false`)

#### **Active** (`active?`)

- **Purpose**: Determines if the setting should be considered usable/active and
  determines if the result of the AppConfig::FOOBAR? method is the
  AppConfig::FOOBAR value if true.
- **Implementation**: Evaluates the `activated` property (defaults to
  `:present?`)
- **Usage**: Can be `true`, `false`, `Symbol`, or `Proc` for custom activation
  logic
- **Indicator**: Shows 🟢 in view output when active

#### **Ignored** (`ignored?`)

- **Purpose**: Skips processing this setting during configuration resolution
- **Implementation**: The `ignored` accessor prevents reading from ENV
  variables
- **Usage**: Set to `true` to skip environment variable lookup for this setting
- **Indicator**: Shows 🙈 in view output when ignored

These concepts work together to provide a comprehensive configuration
management system that tracks the complete lifecycle and status of each setting
from definition through validation and usage.

### Advanced Usage Examples

#### Nested Configuration Modules

ConstConf supports elegant nested module organization where prefixes are
automatically inherited and combined. When you define nested modules, the
library automatically constructs full environment variable names by combining
parent module prefixes with child module names. This creates a clean,
hierarchical configuration structure that's both maintainable and predictable.

```ruby
require 'const_conf'

module AppConfig # default prefix 'APP_CONFIG'
  include ConstConf

  description 'Application Configuration'

  module Database # default prefix 'APP_CONFIG_DATABASE'

    description 'Database settings'

    URL = set do # from ENV['APP_CONFIG_DATABASE_URL'] via default prefix
      description 'Database connection URL'
    end
  end
end
```

To access the nested configuration values in Ruby, you would reference them
through the full module path:

```ruby
# Access the database URL setting
db_url = AppConfig::Database::URL

# Use it in your application
connect_to_database(db_url)

# Check if it's active/available
if db_url = AppConfig::Database::URL?
  # Use the database connection
  connect_to_database(db_url)
end
```

This hierarchical approach makes configuration organization intuitive while
maintaining clear access patterns through Ruby's constant resolution mechanism.

#### Validation and Checks

ConstConf provides powerful validation capabilities through custom check blocks
that allow you to enforce business logic and data integrity rules. These checks
are evaluated during configuration resolution and appear in the view output
with visual indicators.

```ruby
require 'const_conf'

module AppConfig
  include ConstConf

  description 'Application Configuration'
  prefix '' # Use empty prefix for flat environment variable names

  PORT = set do # from ENV['PORT']
    description 'Server port'
    default 3000
    decode(&:to_i)
    check { value >= 1024 } # Port must be >= 1024
  end

  HOST = set do # from ENV['APP_HOST']
    description 'Host name'
    prefix 'APP'
    required { !Rails.env.test? }
    check -> setting { setting.value.present? } # Must not be blank
  end
end
```

The output of `AppConfig.view` is:

```
AppConfig # Application Configuration
├─ prefix ""
├─ 2 settings
├─ AppConfig::PORT # Server port
│  ├─ prefix          ""
│  ├─ env var name    PORT
│  ├─ env var (orig.) nil
│  ├─ default         3000
│  ├─ value           3000
│  ├─ sensitive       ⚪
│  ├─ required        ⚪
│  ├─ configured      ⚪
│  ├─ ignored         ⚪
│  ├─ active          🟢
│  ├─ decoding        ⚙️
│  └─ checked         ✅
└─ AppConfig::HOST # Host name
   ├─ prefix          "APP"
   ├─ env var name    APP_HOST
   ├─ env var (orig.) "www.example.com"
   ├─ default         nil
   ├─ value           "www.example.com"
   ├─ sensitive       ⚪
   ├─ required        🔴
   ├─ configured      🔧
   ├─ ignored         ⚪
   ├─ active          🟢
   ├─ decoding        ⚪
   └─ checked         ✅
```

##### **How Validation Works:**

- **PORT**: The `check { value >= 1024 }` ensures that if a PORT environment
  variable is set, it must be at least 1024 (a privileged port range)
- **HOST**: The `required { !Rails.env.test? }` makes this setting required
  only in non-test environments, and the check validates that the value isn't
  blank

The validation system ensures that your configuration meets both technical
requirements (like port ranges) and business rules (like non-empty hostnames),
making it much harder to deploy applications with invalid configurations.

**When validations fail during confirmation, ConstConf raises specific exceptions:**

- `ConstConf::RequiredValueNotConfigured` for missing required values
- `ConstConf::SettingCheckFailed` for failed custom checks
- These errors are raised immediately during configuration loading to prevent
  runtime issues

#### Complex Settings Examples

```ruby
require 'const_conf'

module AppConfig
  include ConstConf

  description 'Application Configuration'

  # Version validation
  REVISION = set do # from ENV['REVISION']
    description 'Current software revision'
    prefix ''
    required { Rails.env.production? }
    check    { value.blank? || value.to_s =~ /\A\h{7}\z/ }
  end

  # Host validation with regex
  HOST = set do # from ENV['APP_CONFIG_HOST']
    description 'HOST name the application can be reached under'
    required { Rails.env.production? }
    check    { value.blank? || value =~ /\A[a-z\-]+\.[a-z\-\.]+\z/ && value.size <= 253 }
  end

  # Multi-value validation
  HOSTS_ALLOWED = set do # from ENV['APP_CONFIG_HOSTS_ALLOWED']
    description 'Connections under these hostnames are allowed in Rails.'
    default ''
    decode { it.split(?,).map(&:strip) }
    check  { value.all? { |host| host =~ /\A[a-z\-]+\.[a-z\-\.]+\z/ && host.size <= 253 } }
  end

  # Sensitive configuration with validation
  GITHUB_PERSONAL_ACCESS_TOKEN = set do # from ENV['GITHUB_PERSONAL_ACCESS_TOKEN']
    description 'GitHub Personal Access Token for repo access'
    prefix ''
    required { !Rails.env.test? }
    sensitive true
    check { value.to_s =~ /\Aghp_[A-Za-z0-9]{36}\z/ }
  end

  # URI validation
  REDIS_URL = set do # from ENV['REDIS_URL']
    description 'Redis server URL'
    prefix ''
    default 'redis://localhost:6379/1'
    sensitive true
    check { URI.parse(value).scheme == 'redis' rescue false }
  end
end
```

The output of `AppConfig.view` is:

```
AppConfig # Application Configuration
├─ prefix "APP_CONFIG"
├─ 5 settings
├─ AppConfig::REVISION # Current software revision
│  ├─ prefix          ""
│  ├─ env var name    REVISION
│  ├─ env var (orig.) "b781318"
│  ├─ default         nil
│  ├─ value           "b781318"
│  ├─ sensitive       ⚪
│  ├─ required        ⚪
│  ├─ configured      🔧
│  ├─ ignored         ⚪
│  ├─ active          🟢
│  ├─ decoding        ⚪
│  └─ checked         ✅
├─ AppConfig::HOST # HOST name the application can be reached under
│  ├─ prefix          "APP_CONFIG"
│  ├─ env var name    APP_CONFIG_HOST
│  ├─ env var (orig.) "www.example.com"
│  ├─ default         nil
│  ├─ value           "www.example.com"
│  ├─ sensitive       ⚪
│  ├─ required        ⚪
│  ├─ configured      🔧
│  ├─ ignored         ⚪
│  ├─ active          🟢
│  ├─ decoding        ⚪
│  └─ checked         ✅
├─ AppConfig::HOSTS_ALLOWED # Connections under these hostnames are allowed in Rails.
│  ├─ prefix          "APP_CONFIG"
│  ├─ env var name    APP_CONFIG_HOSTS_ALLOWED
│  ├─ env var (orig.) "www.example.com,example.com…
│  ├─ default         ""
│  ├─ value           ["www.example.com", "example…
│  ├─ sensitive       ⚪
│  ├─ required        ⚪
│  ├─ configured      🔧
│  ├─ ignored         ⚪
│  ├─ active          🟢
│  ├─ decoding        ⚙️
│  └─ checked         ✅
├─ AppConfig::GITHUB_PERSONAL_ACCESS_TOKEN # GitHub Personal Access Token for repo access
│  ├─ prefix          ""
│  ├─ env var name    GITHUB_PERSONAL_ACCESS_TOKEN
│  ├─ env var (orig.) 🤫
│  ├─ default         🤫
│  ├─ value           🤫
│  ├─ sensitive       🔒
│  ├─ required        🔴
│  ├─ configured      🔧
│  ├─ ignored         ⚪
│  ├─ active          🟢
│  ├─ decoding        ⚪
│  └─ checked         ✅
└─ AppConfig::REDIS_URL # Redis server URL
   ├─ prefix          ""
   ├─ env var name    REDIS_URL
   ├─ env var (orig.) 🤫
   ├─ default         🤫
   ├─ value           🤫
   ├─ sensitive       🔒
   ├─ required        ⚪
   ├─ configured      🔧
   ├─ ignored         ⚪
   ├─ active          🟢
   ├─ decoding        ⚪
   └─ checked         ✅
```

##### 1. Version Validation (`REVISION`)

```ruby
REVISION = set do
  description 'Current software revision'
  prefix ''
  required { Rails.env.production? }
  check    { value.blank? || value.to_s =~ /\A\h{7}\z/ }
end
```

**Explanation:**

- **Purpose**: Validates that the revision is either blank (not set) or a valid
  7-character hexadecimal string
- **Conditional Required**: Only required in production environment
- **Validation Logic**: Uses regex `/\A\h{7}\z/` to match exactly 7 hexadecimal
  characters (0-9, a-f)
- **Indicator**: Shows `🔴` when required and not satisfied, `✅` when valid

##### 2. Host Validation with Regex (`HOST`)

```ruby
HOST = set do
  description 'HOST name the application can be reached under'
  required { Rails.env.production? }
  check    { value.blank? || value =~ /\A[a-z\-]+\.[a-z\-\.]+\z/ && value.size <= 253 }
end
```

**Explanation:**

- **Purpose**: Validates domain names with proper format and length constraints
- **Conditional Required**: Production-only requirement
- **Regex Pattern**:
  - `/\A[a-z\-]+\.[a-z\-\.]+\z/` - Matches lowercase letters, hyphens, dots in
    hostnames
  - Ensures valid DNS format (e.g., "example.com")
- **Length Check**: Maximum 253 characters per RFC 1035
- **Indicator**: Shows validation status with visual cues

##### 3. Multi-value Validation (`HOSTS_ALLOWED`)

```ruby
HOSTS_ALLOWED = set do
  description 'Connections under these hostnames are allowed in Rails.'
  default ''
  decode { it.split(?,).map(&:strip) }
  check  { value.all? { |host| host =~ /\A[a-z\-]+\.[a-z\-\.]+\z/ && host.size <= 253 } }
end
```

**Explanation:**

- **Purpose**: Validates a comma-separated list of hostnames for allowed
  connections
- **Default Value**: Empty string (no hosts allowed by default)
- **Decoding Logic**: Splits on commas and strips whitespace from each hostname
- **Validation**: Ensures ALL hosts in the list pass the same regex validation
  as single hosts
- **Indicator**: Shows `⚙️` for decoding, `✅` for valid multi-value

##### 4. Sensitive Configuration with Validation (`GITHUB_PERSONAL_ACCESS_TOKEN`)

```ruby
GITHUB_PERSONAL_ACCESS_TOKEN = set do
  description 'GitHub Personal Access Token for repo access'
  prefix ''
  required { !Rails.env.test? }
  sensitive true
  check { value.to_s =~ /\Aghp_[A-Za-z0-9]{36}\z/ }
end
```

**Explanation:**

- **Purpose**: Validates GitHub personal access tokens with strict format
  requirements
- **Conditional Required**: Not required in test environment
- **Sensitive Flag**: Masks the actual value in views (`🤫`)
- **Token Validation**:
  - Must start with `ghp_`
  - Followed by exactly 36 alphanumeric characters
  - Matches GitHub's token format specification
- **Indicator**: Shows both `🔒` (sensitive) and `✅` (validated)

##### 5. URI Validation (`REDIS_URL`)

```ruby
REDIS_URL = set do
  description 'Redis server URL'
  prefix ''
  default 'redis://localhost:6379/1'
  sensitive true
  check { URI.parse(value).scheme == 'redis' rescue false }
end
```

**Explanation:**

- **Purpose**: Validates Redis connection URLs are properly formatted
- **Default Value**: Safe localhost configuration
- **Sensitive Flag**: Masks the URL in views
- **Validation Logic**: Attempts to parse as URI and checks for 'redis' scheme
- **Error Handling**: Uses `rescue false` to gracefully handle invalid URLs
- **Indicator**: Shows `✅` when valid, handles malformed inputs gracefully

##### Key Technical Details

**Conditional Validation**: The use of Procs like `{ Rails.env.production? }`
allows dynamic validation rules based on runtime conditions.

**Safe Error Handling**: The URI parsing example demonstrates proper error
handling with rescue clauses to prevent configuration failures due to malformed
inputs.

**Regex Patterns**: All validations use precise regex patterns that match RFC
standards or specific format requirements, ensuring data integrity.

These examples showcase how ConstConf can handle complex business logic while
maintaining clean, readable configuration definitions. The combination of
conditional requirements, multi-value validation, and sensitive data protection
makes it suitable for production environments with strict security
requirements.

## Rails Integration

ConstConf automatically integrates with Rails:

- Configuration is reloaded when the application prepares configuration
- Works seamlessly with Rails environment variables

## Testing with ConstConf

ConstConf provides built-in testing utilities to make it easy to test your
configuration in isolation.

### Using `const_conf_as` Helper

The `ConstConf::ConstConfHelper` provides a convenient way to temporarily
override constant values during testing:

```ruby
# In your test file
require 'const_conf/spec'

RSpec.describe "MyApp" do
  include ConstConf::ConstConfHelper
  
  it "works with overridden configuration" do
    const_conf_as(
      'AppConfig::DATABASE_URL' => 'postgresql://test:pass@localhost/test',
      'AppConfig::API_KEY' => 'test-key-123'
    )
    
    # Now your tests can use the overridden values
    expect(AppConfig::DATABASE_URL).to eq('postgresql://test:pass@localhost/test')
    expect(AppConfig::API_KEY).to eq('test-key-123')
  end
end
```

To make the helper available throughout your test suite, add this to your
`spec/spec_helper.rb` or `rails_helper.rb`:

```ruby
require 'const_conf/spec'

# spec/spec_helper.rb or spec/rails_helper.rb
RSpec.configure do |config|
  config.include ConstConf::ConstConfHelper
end
```

### Testing Nested Modules

The helper also works with nested configuration modules:

```ruby
const_conf_as(
  'AppConfig::Database::URL' => 'postgresql://test:pass@localhost/test',
  'AppConfig::Database::ENABLED' => true
)
```

This automatically sets up the predicate methods (`?`) for nested constants, so
you can test both the values and their active status:

```ruby
expect(AppConfig::Database::URL?).to be_truthy
expect(AppConfig::Database::ENABLED?).to be true
```

The helper ensures that:
- Constants exist before attempting to override them
- Parent modules are properly handled for nested constants
- Predicate methods are correctly mocked for boolean values
- Proper error handling is in place for missing constants

This approach makes testing configuration-dependent code much easier and more
reliable than relying on environment variables or manual setup.

## Debugging and Inspection

View configuration hierarchies:

```ruby
# Show all configuration settings
AppConfig.view

# Show specific setting details
AppConfig::DATABASE_URL!.view
```

## Download

The homepage of this library is located at

* https://github.com/flori/const_conf

## Author

**ConstConf** was written by Florian Frank [Florian Frank](mailto:flori@ping.de)

## License

[MIT License](./LICENSE)
