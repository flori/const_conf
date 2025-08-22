require 'spec_helper'

describe ConstConf::Setting, protect_env: true do
  let(:parent_namespace) do
    Module.new do
      include ConstConf
    end
  end

  describe "#initialize" do
    it "creates a setting with name and prefix" do
      setting = parent_namespace.module_eval do
        ConstConf::Setting.new(name: "DATABASE_URL", prefix: "APP") do
        end
      end
      expect(setting.name).to eq "DATABASE_URL"
      expect(setting.prefix).to eq "APP"
    end

    it "constructs env var name from prefix and name" do
      setting = parent_namespace.module_eval do
        ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        end
      end
      expect(setting.env_var_name).to eq "APP_DATABASE_URL"
    end
  end

  describe "#env_var_name" do
    it "handles nested module names with double colons" do
      setting = parent_namespace.module_eval do
        ConstConf::Setting.new(name: ["APP", "EMAIL", "NOTIFY_USER"], prefix: "APP") do
        end
      end
      expect(setting.env_var_name).to eq "APP_EMAIL_NOTIFY_USER"
    end

    it "uses empty prefix when none provided" do
      setting = ConstConf::Setting.new(name: ["APP", "SERVICE", "DATABASE_URL"], prefix: '')
      allow(setting).to receive(:parent_namespace).and_return('APP::SERVICE')
      expect(setting.env_var_name).to eq "DATABASE_URL"
    end
  end

  describe "#value" do
    before do
      ENV['APP_DATABASE_URL'] = "postgres://localhost/test"
      ENV['APP_HOSTNAMES']    = nil
    end

    it "returns environment variable value when present" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        description 'nope'
        default "sqlite3://default.db"
      end
      expect(setting.value).to eq "postgres://localhost/test"
    end

    it "returns default value when env var is not set" do
      ENV['APP_DATABASE_URL'] = nil

      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        default "sqlite3://default.db"
      end
      expect(setting.value).to eq "sqlite3://default.db"
    end

    it "applies decode logic when present" do
      setting = ConstConf::Setting.new(name: ["APP", "HOSTNAMES"], prefix: "APP") do
        default "foo,bar,baz"
        decode ->(val) { val.split(",") }
      end
      expect(setting.value).to eq ["foo", "bar", "baz"]
    end
  end

  describe "#active?" do
    it "returns true when activated with non-nil value" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        activated true
        default "sqlite3://default.db"
      end
      expect(setting.active?).to be true
    end

    it "returns false when not activated" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        activated false
      end
      expect(setting.active?).to be false
    end

    it "evaluates Proc with value when activated is a Proc (arity 1)" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        activated ->(value) { value.present? }
        default "test_value"
      end
      expect(setting.active?).to be true
    end

    it "evaluates Proc without arguments when activated is a Proc (arity 0)" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        activated -> { true }
        default "test_value"
      end
      expect(setting.active?).to be true
    end

    it "returns false when Proc evaluation returns false (arity 1)" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        activated ->(value) { value.nil? }
        default "test_value"
      end
      expect(setting.active?).to be false
    end

    it "returns false when Proc evaluation returns false (arity 0)" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        activated -> { false }
        default "test_value"
      end
      expect(setting.active?).to be false
    end

    it "calls method on value when activated is a Symbol" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        activated :present?
        default "test_value"
      end
      expect(setting.active?).to be true
    end

    it "returns false when Symbol method returns false on value" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        activated :empty?
        default "test_value"
      end
      expect(setting.active?).to be false
    end

    it "returns false when Symbol method returns false on nil value" do
      ENV['APP_DATABASE_URL'] = nil

      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        activated :present?
        default nil
      end
      expect(setting.active?).to be false
    end
  end

  describe "#configured?" do
    it "returns true when environment variable is set" do
      ENV['APP_TEST_VAR'] = 'value'

      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        default "default"
      end

      expect(setting.configured?).to be true
    end

    it "returns false when environment variable is not set" do
      ENV['APP_TEST_VAR'] = nil

      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        default "default"
      end

      expect(setting.configured?).to be false
    end

    it "returns false when ignored and environment variable is set" do
      ENV['APP_TEST_VAR'] = 'value'

      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        ignored true
        default "default"
      end

      expect(setting.configured?).to be false
    end

    it "returns false when configured value is nil and no default" do
      ENV['APP_TEST_VAR'] = nil

      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        # No default specified
      end

      expect(setting.configured?).to be false
    end

    it "returns true when configured value is present" do
      ENV['APP_TEST_VAR'] = 'some_value'

      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        default nil
      end

      expect(setting.configured?).to be true
    end

    it "returns false when configured value is an empty string" do
      ENV['APP_TEST_VAR'] = ''

      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        default "default"
      end

      expect(setting.configured?).to be true
    end
  end

  describe "#required?" do
    it "returns true when required is set to true" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        required true
      end
      expect(setting.required?).to be true
    end

    it "returns false when required is not set" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP")
      expect(setting.required?).to be false
    end

    it "returns true when required is a proc that returns true (arity 1)" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        required ->(value) { value.present? }
      end
      allow(setting).to receive(:configured_value_or_default_value).and_return("test_value")
      expect(setting.required?).to be true
    end

    it "returns false when required is a proc that returns false (arity 1)" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        required ->(value) { value.nil? }
      end
      allow(setting).to receive(:configured_value_or_default_value).and_return("test_value")
      expect(setting.required?).to be false
    end

    it "returns true when required is a proc that returns true (arity 0)" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        required -> { true }
      end
      expect(setting.required?).to be true
    end

    it "returns false when required is a proc that returns false (arity 0)" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        required -> { false }
      end
      expect(setting.required?).to be false
    end
  end

  describe "#confirm!" do
    it "raises RequiredValueNotConfigured when required but not configured" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        description 'nope'
        required true
      end
      expect { setting.confirm! }.to raise_error(ConstConf::RequiredValueNotConfigured)
    end

    it "raises RequiredDescriptionNotConfigured if description is missing" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        required true
        activated true
      end
      expect { setting.confirm! }.to raise_error(ConstConf::RequiredDescriptionNotConfigured)
    end

    it "does not raise error when required and configured" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        description 'nope'
        required true
        activated true
      end
      allow(setting).to receive(:configured_value).and_return('was set')
      expect { setting.confirm! }.not_to raise_error
    end

    context "when check fails" do
      it "raises SettingCheckFailed error" do
        setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
          description 'Test setting'
          check ->(setting) { false }  # Always fail
        end
        expect { setting.confirm! }.to raise_error(ConstConf::SettingCheckFailed)
      end
    end

    context "when check passes" do
      it "does not raise error" do
        setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
          description 'Test setting'
          check ->(setting) { true }  # Always pass
        end
        expect { setting.confirm! }.not_to raise_error
      end
    end
  end

  describe "#ignored?" do
    it "returns true when ignored is set to true" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP") do
        description 'nope'
        ignored true
      end
      expect(setting.ignored?).to be true
    end

    it "returns false when ignored is not set" do
      setting = ConstConf::Setting.new(name: ["APP", "DATABASE_URL"], prefix: "APP")
      expect(setting.ignored?).to be false
    end
  end

  describe "#value_provided?" do
    it "returns true when configured value exists" do
      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        default "default"
      end

      allow(setting).to receive(:configured_value_or_default_value).and_return("value")

      expect(setting.value_provided?).to be true
    end

    it "returns false when no configured value or default exists" do
      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        default nil
      end

      allow(setting).to receive(:configured_value_or_default_value).and_return(nil)

      expect(setting.value_provided?).to be false
    end
  end

  describe "#default_value" do
    it "returns the default value when it's not a proc" do
      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        default "test_default"
      end

      expect(setting.default_value).to eq "test_default"
    end

    it "evaluates the default when it's a proc" do
      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        default -> { "computed_default" }
      end

      expect(setting.default_value).to eq "computed_default"
    end

    it "handles nil defaults properly" do
      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        default nil
      end

      expect(setting.default_value).to be_nil
    end
  end

  describe "#configured_value_or_default_value" do
    it "returns configured value when present" do
      ENV['APP_TEST_VAR'] = 'configured_value'

      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        default "default_value"
      end

      expect(setting.configured_value_or_default_value).to eq "configured_value"
    end

    it "returns default value when configured value is nil" do
      ENV['APP_TEST_VAR'] = nil

      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        default "default_value"
      end

      expect(setting.configured_value_or_default_value).to eq "default_value"
    end

    it "returns nil when both configured and default values are nil" do
      ENV['APP_TEST_VAR'] = nil

      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        default nil
      end

      expect(setting.configured_value_or_default_value).to be_nil
    end
  end

  describe "#configured_value" do
    it "returns env var value when set and not ignored" do
      ENV['APP_TEST_VAR'] = 'value'

      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        default "default"
      end

      expect(setting.configured_value).to eq "value"
    end

    it "returns nil when env var is not set" do
      ENV['APP_TEST_VAR'] = nil

      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        default "default"
      end

      expect(setting.configured_value).to be_nil
    end

    it "returns nil when ignored" do
      ENV['APP_TEST_VAR'] = 'value'

      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        ignored true
        default "default"
      end

      expect(setting.configured_value).to be_nil
    end
  end

  describe "#checked?" do
    context "with default check (always passes)" do
      it "returns :unchecked_true by default" do
        setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
          description 'Test setting'
        end
        expect(setting.checked?).to be :unchecked_true
      end
    end

    context "with custom check that passes" do
      it "returns true when custom check passes" do
        setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
          description 'Test setting'
          check ->(setting) { true }  # Always pass
        end
        expect(setting.checked?).to be true
      end
    end

    context "with custom check that fails" do
      it "returns false when custom check fails" do
        setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
          description 'Test setting'
          check ->(setting) { false }  # Always fail
        end
        expect(setting.checked?).to be false
      end
    end

    context "with custom check that uses setting value" do
      it "returns true when check validates value properly" do
        ENV['APP_TEST_VAR'] = 'valid_value'

        setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
          description 'Test setting'
          check ->(setting) {
            value = setting.value
            !value.nil? && value.length > 5  # Only pass if value length > 5
          }
        end
        expect(setting.checked?).to be true
      end

      it "returns false when check validates value improperly" do
        ENV['APP_TEST_VAR'] = 'short'

        setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
          description 'Test setting'
          check ->(setting) {
            value = setting.value
            !value.nil? && value.length > 5  # Only pass if value length > 5
          }
        end
        expect(setting.checked?).to be false
      end
    end
  end

  describe "#decoded_value" do
    it "applies decoding when proc is present" do
      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        decode ->(val) { val.upcase }
      end
      expect(setting).to be_decoding
      expect(setting.send(:decoded_value, "test")).to eq "TEST"
    end

    it "returns value unchanged when no decoding is present" do
      setting = ConstConf::Setting.new(name: ["APP", "TEST_VAR"], prefix: "APP") do
        decode nil
      end

      expect(setting.send(:decoded_value, "test")).to eq "test"
    end
  end

  context 'with parent namespace' do
    module TestParentNamespace
      include ConstConf
    end

    describe "#view" do
      it "generates tree structure for setting" do
        setting = TestParentNamespace.module_eval do
          ConstConf::Setting.new(name: ["APP", "VIEW_TEST"], prefix: "APP") do
            description 'View test variable'
            default 'view_default'
            required true
            sensitive true
          end
        end

        # Test that view works with StringIO
        io = StringIO.new
        setting.view(io: io)
        output = io.string

        expect(output).to include('VIEW_TEST')
        expect(output).to include('View test variable')
        expect(output).to include('APP_VIEW_TEST')
        expect(output).not_to include('view_default')
        expect(output).to include('required        🔴')
        expect(output).to include('sensitive       🔒')
      end

      it "shows check status in view output" do
        setting = TestParentNamespace.module_eval do
          ConstConf::Setting.new(name: ["APP", "CHECK_VAR"], prefix: "APP") do
            description 'Check test variable'
            check ->(setting) { true }
          end
        end

        io = StringIO.new
        setting.view(io: io)
        output = io.string

        expect(output).to include('checked         ✅')
      end

      it "shows failed check in view output" do
        setting = TestParentNamespace.module_eval do
          ConstConf::Setting.new(name: ["APP", "FAILED_VAR"], prefix: "APP") do
            description 'Failed check variable'
            check ->(setting) { false }
          end
        end

        io = StringIO.new
        setting.view(io: io)
        output = io.string

        expect(output).to include('checked         ❌')
      end
    end

    describe "#to_s" do
      it "returns string representation with all metadata" do
        setting = TestParentNamespace.module_eval do
          ConstConf::Setting.new(name: ["APP", "TO_S_TEST"], prefix: "APP") do
            description 'To string test'
            default 'to_string_default'
            required true
          end
        end

        output = setting.to_s
        expect(output).to be_a(String)
        expect(output).to include('TO_S_TEST')
        expect(output).to include('To string test')
        expect(output).to include('default         "to_string_default"')
        expect(output).to include('required        🔴')
      end
    end

    describe "#inspect" do
      it "returns same format as to_s" do
        setting = TestParentNamespace.module_eval do
          ConstConf::Setting.new(name: ["APP", "INSPECT_TEST"], prefix: "APP") do
            description 'Inspect test'
            default 'inspect_default'
          end
        end

        inspect_output = setting.inspect
        to_s_output = setting.to_s

        expect(inspect_output).to be_a(String)
        expect(to_s_output).to be_a(String)
        expect(inspect_output).to eq to_s_output
      end

      it "returns same format as to_s without colors" do
        require 'irb'
        allow(IRB.conf).to receive(:[]).with(:USE_COLORIZE).and_return true

        setting = TestParentNamespace.module_eval do
          ConstConf::Setting.new(name: ["APP", "INSPECT_TEST"], prefix: "APP") do
            description 'Inspect test'
            default 'inspect_default'
          end
        end

        inspect_output = setting.inspect
        to_s_output = setting.to_s

        expect(inspect_output).to be_a(String)
        expect(to_s_output).to be_a(String)
        expect(inspect_output).to eq Term::ANSIColor.uncolor(to_s_output)
      end
    end
  end
end
