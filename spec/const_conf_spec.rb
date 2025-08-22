require 'spec_helper'

describe ConstConf do
  before do
    if Object.const_defined?(:TestConstConf)
      Object.send(:remove_const, :TestConstConf)
    end
  end

  describe 'in ConstConf module' do
    context 'reloading' do
      before do
        module TestConstConf
          include ConstConf

          description 'foo'

          TEST = set do
            description 'bar'
          end
        end
      end

      describe '.register' do
        it 'registers configurations' do
          expect(ConstConf.module_files).to include(TestConstConf => __FILE__)
        end
      end

      describe '.destroy' do
        it 'can be destroyed' do
          expect(ConstConf.destroy).to include(__FILE__)
        end
      end

      describe '.reload' do
        it 'first destroys and then reloads' do
          files = %w[ /path/to/foo.rb ]
          expect(ConstConf).to receive(:destroy).and_return(files)
          expect(ConstConf).to receive(:load).with(files.first)
          ConstConf.reload
        end
      end
    end

    describe 'in including modules' do
      describe '.plugin' do
        before do
          module TestConstConf
            include ConstConf

            plugin ConstConf::FilePlugin

            description 'foo'

            TEST = set do
              description 'test'
              default 'bar'
            end
          end
        end

        it 'can include FilePlugin' do
          expect(ConstConf::Setting).to receive(:include).
            with(ConstConf::FilePlugin).
            and_call_original
          TestConstConf.plugin(ConstConf::FilePlugin)
        end
      end

      describe '.description' do
        before do
          module TestConstConf
            include ConstConf
          end
        end

        it 'sets and retrieves module description' do
          expect { TestConstConf.description "Test Configuration" }
            .to change { TestConstConf.description }
            .from(nil)
            .to("Test Configuration")
        end
      end

      context 'nested configurations' do
        before do
          module TestNestedConstConf
            include ConstConf

            description 'TestConstConf'

            module InnerConstConf
              description 'InnerConstConf'
            end
          end
        end

        describe '.outer_configuration' do
          it 'knows about outer_configuration' do
            expect(TestNestedConstConf::InnerConstConf.outer_configuration).
              to eq TestNestedConstConf
          end
        end

        describe '.all_configurations' do
          it 'can return all configurations' do
            expect(TestNestedConstConf.all_configurations).to eq(
              [ TestNestedConstConf, TestNestedConstConf::InnerConstConf ]
            )
          end
        end

        describe '.nested_configurations' do
          it 'can return nested configurations' do
            expect(TestNestedConstConf.nested_configurations).to eq(
              [ TestNestedConstConf::InnerConstConf ]
            )
          end

          describe '.each_nested_configuration' do
            it 'can iterate over nested configurations' do
              expect(TestNestedConstConf.each_nested_configuration).
                to be_a Enumerator
              expect(TestNestedConstConf.each_nested_configuration.to_a).
                to eq([ TestNestedConstConf, TestNestedConstConf::InnerConstConf ])
            end
          end
        end

        describe '.env_var_names' do
          it 'returns the names environment variables' do
            ENV['FOO'] = 'test_value'
            module TestConstConf
              include ConstConf
              description 'foo foo'
              FOO = set do
                prefix ''
                description 'foo'
              end
            end
            expect(TestConstConf.env_var_names).to eq %w[ FOO ]
          end
        end
      end

      describe '.env_vars' do
        it 'returns a hash of environment variable values' do
          ENV['FOO'] = 'test_value'
          module TestConstConf
            include ConstConf

            description 'foo foo'
            FOO = set do
              prefix ''
              description 'foo'
            end
          end
          expect(TestConstConf.env_vars).to eq(
            'FOO' => 'test_value'
          )
        end
      end

      context 'with a setting' do
        before do
          module TestConstConf
            include ConstConf

            description 'foo'

            TEST = set do
              description 'test'
              default 'bar'
            end
          end
        end

        describe '.prefix' do
          it 'sets and retrieves prefix properly' do
            expect { TestConstConf.prefix "FOO" }.to change { TestConstConf.prefix }.
              from("TEST_CONST_CONF").to("FOO")
          end
        end

        it 'modifies settings after set' do
          expect(TestConstConf.settings['TEST_CONST_CONF_TEST']).
            to be_a(ConstConf::Setting)
        end

        describe '.setting_for' do
          it 'can be returned' do
            expect(TestConstConf.setting_for('TEST_CONST_CONF_TEST')).
              to be_a ConstConf::Setting
          end
        end

        describe '.setting_value_for' do
          it 'has a value that be returned' do
            expect(TestConstConf.setting_for('TEST_CONST_CONF_TEST').value).
              to eq 'bar'
          end

          describe '.view' do
            it 'renders tree view' do
              expect(ConstConf::Tree).to receive(:from_const_conf).with(
                TestConstConf
              )
              TestConstConf.view
            end
          end
        end
      end
    end
  end
end
