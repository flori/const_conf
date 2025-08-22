require 'spec_helper'

describe ConstConf::Tree do
  module ModuleWithSettings
    include ConstConf
    description 'Test Configuration'
    prefix 'TEST'

    TEST_VAR = set do
      description 'A test variable'
      prefix '' # Remove the superflous TEST prefix for env var TEST_VAR
      default 'default_value'
      required true
    end

    NESTED_CONFIG = set do
      # prefix is inherited from ModuleWithSettings's 'TEST', make this env var
      # TEST_NESTED_CONFIG
      description 'Nested configuration'
      default 'nested_default'
    end
  end

  describe '.from_const_conf' do
    context 'with a ConstConf module' do
      it 'converts module to tree structure' do
        tree = ConstConf::Tree.from_const_conf(ModuleWithSettings)

        expect(tree).to be_a(ConstConf::Tree)
        expect(tree.to_s).to include('Test Configuration')
        expect(tree.to_s).to include('::TEST_VAR')
        expect(tree.to_s).to include('TEST_NESTED_CONFIG')
        expect(tree.to_s).to include('::NESTED_CONFIG')
      end
    end

    context 'with a Setting object' do
      let(:setting) do
        ModuleWithSettings::TEST_VAR!
      end

      it 'converts setting to tree structure' do
        tree = ConstConf::Tree.from_const_conf(setting)

        expect(tree).to be_a(ConstConf::Tree)
        expect(tree.to_s).to include('TEST_VAR')
        expect(tree.to_s).to include('A test variable')
      end
    end

    context 'with invalid argument' do
      it 'raises ArgumentError' do
        expect {
          ConstConf::Tree.from_const_conf(Object.new)
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'Tree instance methods' do
    let(:tree) do
      ConstConf::Tree.new('Test Node')
    end

    describe '#initialize' do
      it 'creates tree with name and value' do
        tree = ConstConf::Tree.new('Test')
        expect(tree.instance_variable_get(:@name)).to eq 'Test'
      end
    end

    describe '#<<' do
      it 'adds child nodes' do
        child = ConstConf::Tree.new('Child')
        tree << child

        expect(tree.instance_variable_get(:@children)).to include(child)
      end
    end

    describe '#to_enum' do
      it 'yields tree structure with proper indentation' do
        child1 = ConstConf::Tree.new('Child 1')
        child2 = ConstConf::Tree.new('Child 2')

        tree << child1
        tree << child2

        enum = tree.to_enum
        result = enum.to_a

        expect(result).to be_an(Array)
        expect(result.size).to be >= 3 # root + children
      end
    end

    describe '#to_s' do
      it 'returns formatted string representation' do
        tree << ConstConf::Tree.new('Child Node')

        result = tree.to_s
        expect(result).to be_a(String)
        expect(result).not_to be_empty
      end
    end

    describe '#default_utf8', protect_env: true do
      context 'when LANG contains utf-8' do
        before do
          ENV['LANG'] = 'en_US.UTF-8'
        end

        it 'returns true' do
          expect(tree.default_utf8).to be true
        end
      end

      context 'when LANG does not contain utf-8' do
        before do
          ENV['LANG'] = 'en_US.ISO8859-1'
        end

        it 'returns false' do
          expect(tree.default_utf8).to be false
        end
      end
    end
  end

  module ParentModule
    include ConstConf
    description 'Parent Configuration'
    prefix 'PARENT'

    module NestedModule
      include ConstConf
      description 'Nested Config'
      prefix 'NESTED'

      NESTED_VAR = set do
        description 'Nested variable'
        default 'nested_value'
      end
    end

    PARENT_VAR = set do
      description 'Parent variable'
      default 'parent_value'
    end
  end

  describe 'tree rendering with nested modules' do
    it 'handles nested module structures' do
      tree = ConstConf::Tree.from_const_conf(ParentModule)

      # Should contain parent and nested module information
      expect(tree.to_s).to include('Parent Configuration')
      expect(tree.to_s).to include('Nested Config')
      expect(tree.to_s).to include('::PARENT_VAR')
      expect(tree.to_s).to include('PARENT_PARENT_VAR')
      expect(tree.to_s).to include('::NESTED_VAR')
      expect(tree.to_s).to include('NESTED_NESTED_VAR')
    end
  end

  describe 'setting details rendering' do
    let(:setting) do
      ModuleWithSettings::TEST_VAR!
    end

    it 'renders detailed setting information' do
      tree = ConstConf::Tree.from_const_conf(setting)

      # Should include various setting metadata
      result = tree.to_s

      expect(result).to include('TEST_VAR')
      expect(result).to include('A test variable')
      expect(result).to include('prefix')
      expect(result).to include('env var name')
      expect(result).to include('default')
      expect(result).to include('value')
    end
  end
end
