require 'spec_helper'

describe ConstConf::SettingAccessor do
  let(:klass) do
    Class.new do
      extend ConstConf::SettingAccessor
    end
  end

  describe '.setting_accessor' do
    context 'with default value' do
      before do
        klass.setting_accessor :foobar, 'default_value'
      end

      it 'returns default value when not set' do
        instance = klass.new
        expect(instance.foobar).to eq 'default_value'
      end

      it 'returns set value when explicitly set' do
        instance = klass.new
        instance.foobar 'explicit_value'
        expect(instance.foobar).to eq 'explicit_value'
      end
    end

    context 'with block default' do
      before do
        klass.setting_accessor :foobar do
          'block_default'
        end
      end

      it 'evaluates block for default value' do
        instance = klass.new
        expect(instance.foobar).to eq 'block_default'
      end

      it 'returns set value when explicitly set' do
        instance = klass.new
        instance.foobar 'explicit_value'
        expect(instance.foobar).to eq 'explicit_value'
      end
    end

    context 'with arg_block' do
      before do
        klass.setting_accessor :foobar
      end

      it 'foo' do
        instance = klass.new
        expect(instance.foobar).to be nil
        instance.foobar do
          :bar
        end
        expect(instance.foobar).to be_a Proc
        expect(instance.foobar.()).to be :bar
      end
    end

    context 'setter mode behavior' do
      before do
        klass.setting_accessor :required_setting, nil
      end

      it 'raises ArgumentError when in setter_mode and value is nil' do
        # This requires setting up thread-local setter_mode
        expect do
          instance = klass.new
          # Simulate setter mode behavior
          allow(klass).to receive(:setter_mode).and_return(true)
          instance.required_setting
        end.to raise_error(ArgumentError, /need an argument/)
      end
    end

    context 'with positional argument' do
      before do
        klass.setting_accessor :foobar, 'default'
      end

      it 'accepts positional argument for setting value' do
        instance = klass.new
        # This is a bit tricky to test since the method signature is complex
        expect(instance.foobar('explicit')).to eq 'explicit'
      end
    end

    context 'with block argument' do
      before do
        klass.setting_accessor :foobar, 'default'
      end

      it 'accepts block argument for setting value' do
        instance = klass.new
        result = instance.foobar { 'block_value' }
        expect(result).to be_a Proc
        expect(instance.foobar.()).to eq 'block_value'
      end
    end
  end

  describe 'thread_local behavior' do
    it 'manages thread-local setter_mode state' do
      expect(klass.setter_mode).to be_falsey
      klass.enable_setter_mode do
        expect(klass.setter_mode).to be_truthy
      end
      expect(klass.setter_mode).to be_falsey
    end
  end
end
