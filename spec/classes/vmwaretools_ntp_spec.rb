require 'spec_helper'

describe 'vmwaretools::ntp', :type => 'class' do
  describe 'without base class defined, non-vmware platform' do
    on_supported_os.each do |os,facts|
      context "on #{os}" do
        let(:facts) do
          facts.merge (
            {
              :virtual => 'foo'
            }
          )
        end

        it do
          is_expected.not_to contain_exec('vmware-tools.syncTime')
        end
      end
    end
  end

  describe 'without base class defined, vmware platform' do
    on_supported_os.each do |os,facts|
      context "on #{os}" do
        let(:facts) do
          facts.merge (
            {
              :virtual => 'vmware'
            }
          )
        end

        it do
          is_expected.to compile.and_raise_error(/The class vmwaretools must be declared/)
        end
      end
    end
  end

  describe 'with base class defined, on a supported osfamily, non-vmware platform' do
    let(:pre_condition) { "class { 'vmwaretools': package => 'RandomData' }" }

    on_supported_os.each do |os,facts|
      context "on #{os}" do
        let(:facts) do
          facts.merge (
            {
              :virtual => 'foo'
            }
          )
        end
        it do
          is_expected.not_to contain_exec('vmware-tools.syncTime')
        end
      end
    end
  end

  describe 'with base class defined, on a supported osfamily, vmware platform' do
    describe "for service_pattern vmware-guestd" do
      let :pre_condition do
        "class { 'vmwaretools':
          package       => 'RandomData',
          tools_version => '3.0u5',
        }"
      end

      on_supported_os.each do |os,facts|
        context "on #{os}" do
          let(:facts) do
            facts.merge (
              {
                :virtual => 'vmware'
              }
            )
          end
          it do
            is_expected.to contain_exec('vmware-tools.syncTime').with(
              'command' => 'vmware-guestd --cmd "vmx.set_option synctime 1 0" || true'
            )
          end
        end
      end
    end

    describe "for service_pattern vmtoolsd" do
      let :pre_condition do
        "class { 'vmwaretools':
          package       => [ 'RandomData', 'OtherData', ],
          tools_version => '4.1latest',
        }"
      end

      on_supported_os.each do |os,facts|
        context "on #{os}" do
          let(:facts) do
            facts.merge (
              {
                :virtual => 'vmware'
              }
            )
          end

          it do
            is_expected.to contain_exec('vmware-tools.syncTime').with(
              'command' => 'vmware-toolbox-cmd timesync disable'
            )
          end
        end
      end
    end
  end
end
