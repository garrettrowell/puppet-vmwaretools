require 'spec_helper'

describe 'vmwaretools', :type => 'class' do
  context 'on a non-supported osfamily' do
    let :facts do
      {
        :osfamily               => 'foo',
        :operatingsystem        => 'foo',
        :operatingsystemrelease => '1.0',
        :virtual                => 'foo'
      }
    end

    it do
      is_expected.not_to contain_class('vmwaretools::repo')
      is_expected.not_to contain_package('vmware-tools')
      is_expected.not_to contain_package('vmware-tools-nox')
      is_expected.not_to contain_package('vmware-tools-esx-kmods')
      is_expected.not_to contain_exec('vmware-uninstall-tools')
      is_expected.not_to contain_exec('vmware-uninstall-tools-local')
      is_expected.not_to contain_file_line('disable-tools-version')
      is_expected.not_to contain_service('vmware-tools')
      is_expected.not_to contain_service('vmware-tools-services')
      is_expected.not_to contain_file('/etc/udev/rules.d/99-vmware-scsi-udev.rules')
    end
  end

  context 'on a supported osfamily, non-vmware platform' do
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
          is_expected.not_to contain_class('vmwaretools::repo')
          is_expected.not_to contain_package('vmware-tools')
          is_expected.not_to contain_package('vmware-tools-nox')
          is_expected.not_to contain_package('vmware-tools-esx-nox')
          is_expected.not_to contain_package('vmware-tools-esx-kmods')
          is_expected.not_to contain_exec('vmware-uninstall-tools')
          is_expected.not_to contain_exec('vmware-uninstall-tools-local')
          is_expected.not_to contain_file_line('disable-tools-version')
          is_expected.not_to contain_service('vmware-tools')
          is_expected.not_to contain_service('vmware-tools-services')
          is_expected.not_to contain_file('/etc/udev/rules.d/99-vmware-scsi-udev.rules')
          is_expected.not_to contain_exec('udevrefresh')
        end
      end
    end
  end

  context 'on a supported osfamily, vmware platform, non-supported operatingsystem' do
    describe "for operating system Fedora" do
      let :facts do
        {
          :virtual                => 'vmware',
          :osfamily               => 'RedHat',
          :operatingsystem        => 'Fedora',
          :operatingsystemrelease => '1.0'
        }
      end

      it do
        is_expected.not_to contain_class('vmwaretools::repo')
        is_expected.not_to contain_package('vmware-tools')
        is_expected.not_to contain_package('vmware-tools-nox')
        is_expected.not_to contain_package('vmware-tools-esx-nox')
        is_expected.not_to contain_package('vmware-tools-esx-kmods')
        is_expected.not_to contain_exec('vmware-uninstall-tools')
        is_expected.not_to contain_exec('vmware-uninstall-tools-local')
        is_expected.not_to contain_file_line('disable-tools-version')
        is_expected.not_to contain_service('vmware-tools')
        is_expected.not_to contain_service('vmware-tools-services')
        is_expected.not_to contain_file('/etc/udev/rules.d/99-vmware-scsi-udev.rules')
        is_expected.not_to contain_exec('udevrefresh')
      end
    end
  end

  context 'on a supported osfamily, vmware platform, default parameters' do
    on_supported_os.each do |os,facts|
      context "on #{os}" do
        let(:facts) do
          facts.merge (
            {
              :virtual       => 'vmware',
              :puppetversion => Puppet.version
            }
          )
        end

        case facts[:osfamily]
        when 'RedHat'
          case facts[:operatingsystemmajrelease]
          when '5'
            it do
              is_expected.to contain_class('vmwaretools::repo').with(
                'before' => ['Package[vmware-tools-esx-nox]', 'Package[vmware-tools-esx-kmods]']
              )
              is_expected.to contain_package('vmware-tools-esx-kmods')
              is_expected.to contain_service('vmware-tools-services').with(
                'pattern' => 'vmtoolsd'
              )
              is_expected.not_to contain_service('vmware-tools-services').with(
                'start' => '/sbin/start vmware-tools-services'
              )
              is_expected.to contain_file('/etc/udev/rules.d/99-vmware-scsi-udev.rules').with(
                'content' => "#\n# VMware SCSI devices Timeout adjustment\n#\n# Modify the timeout value for VMware SCSI devices so that\n# in the event of a failover, we don't time out.\n# See Bug 271286 for more information.\n\n\nACTION==\"add\", SUBSYSTEMS==\"scsi\", ATTRS{vendor}==\"VMware  \", ATTRS{model}==\"Virtual disk    \", RUN+=\"/bin/sh -c 'echo 180 >/sys$DEVPATH/timeout'\"\nACTION==\"add\", SUBSYSTEMS==\"scsi\", ATTRS{vendor}==\"VMware, \", ATTRS{model}==\"VMware Virtual S\", RUN+=\"/bin/sh -c 'echo 180 >/sys$DEVPATH/timeout'\"\n\n"
              )
              is_expected.to contain_exec('udevrefresh').with(
                'refreshonly' => true,
                'command'     => '/sbin/udevcontrol reload_rules && /sbin/start_udev'
              )
            end
          when '6'
            let(:params) do
              {
                :scsi_timeout => '14400'
              }
            end

            it do
              is_expected.to contain_class('vmwaretools::repo').with(
                'before' => ['Package[vmware-tools-esx-nox]', 'Package[vmware-tools-esx-kmods]']
              )
              is_expected.to contain_package('vmware-tools-esx-kmods')
              is_expected.not_to contain_service('vmware-tools-services').with(
                'pattern' => 'vmtoolsd'
              )
              is_expected.to contain_service('vmware-tools-services').with(
                'start' => '/sbin/start vmware-tools-services'
              )
              is_expected.to contain_file('/etc/udev/rules.d/99-vmware-scsi-udev.rules').with(
                'content' => "#\n# VMware SCSI devices Timeout adjustment\n#\n# Modify the timeout value for VMware SCSI devices so that\n# in the event of a failover, we don't time out.\n# See Bug 271286 for more information.\n\n\nACTION==\"add\", SUBSYSTEMS==\"scsi\", ATTRS{vendor}==\"VMware  \", ATTRS{model}==\"Virtual disk    \", RUN+=\"/bin/sh -c 'echo 14400 >/sys$DEVPATH/timeout'\"\nACTION==\"add\", SUBSYSTEMS==\"scsi\", ATTRS{vendor}==\"VMware, \", ATTRS{model}==\"VMware Virtual S\", RUN+=\"/bin/sh -c 'echo 14400 >/sys$DEVPATH/timeout'\"\n\n"
              )
              is_expected.to contain_exec('udevrefresh').with(
                'refreshonly' => true,
                'command'     => '/sbin/udevadm control --reload-rules && /sbin/udevadm trigger --action=add --subsystem-match=scsi'
              )
            end
          end
        when 'SuSE'
          it do
            is_expected.to contain_class('vmwaretools::repo').with(
              'before' => ['Package[vmware-tools-esx-nox]', 'Package[vmware-tools-esx-kmods-default]']
            )
            is_expected.to contain_package('vmware-tools-esx-kmods-default')
            is_expected.to contain_service('vmware-tools-services').with(
              'pattern' => 'vmtoolsd'
            )
            is_expected.not_to contain_service('vmware-tools-services').with(
              'start' => '/sbin/start vmware-tools-services'
            )
          end
        when 'Debian'
          it do
            is_expected.to contain_class('vmwaretools::repo').with(
              'before' => ['Package[vmware-tools-esx-nox]', 'Package[vmware-tools-esx-kmods-3.8.0-29-generic]']
            )
            is_expected.to contain_package('vmware-tools-esx-kmods-3.8.0-29-generic')
            is_expected.to contain_service('vmware-tools-services').with(
              'pattern' => 'vmtoolsd'
            )
            is_expected.not_to contain_service('vmware-tools-services').with(
              'start' => '/sbin/start vmware-tools-services'
            )
          end
        else
          it do
            is_expected.to contain_class('vmwaretools::repo').with(
              :tools_version         => 'latest',
              :reposerver            => 'http://packages.vmware.com',
              :repopath              => '/tools',
              :just_prepend_repopath => 'false',
              :priority              => '50',
              :protect               => '0',
              :gpgkey_url            => 'http://packages.vmware.com/tools/',
              :proxy                 => 'absent',
              :proxy_username        => 'absent',
              :proxy_password        => 'absent',
              :ensure                => 'present'
            )
          end

          it do
            is_expected.to contain_package('VMwareTools').with(
              'ensure' => 'absent'
            )
          end

          it do
            is_expected.to contain_exec('vmware-uninstall-tools').with(
              'command' => '/usr/bin/vmware-uninstall-tools.pl && rm -rf /usr/lib/vmware-tools'
            )
          end

          it do
            is_expected.to contain_exec('vmware-uninstall-tools-local').with(
              'command' => '/usr/local/bin/vmware-uninstall-tools.pl && rm -rf /usr/local/lib/vmware-tools'
            )
          end

          it do
            is_expected.to contain_file_line('disable-tools-version').with(
              'path' => '/etc/vmware-tools/tools.conf',
              'line' => 'disable-tools-version = "true"'
            )
          end

          it do
            is_expected.to contain_package('vmware-tools-esx-nox')
          end
        end
      end
    end
  end

  context 'on a supported operatingsystem, vmware platform, custom parameters' do
    on_supported_os.each do |os,facts|
      context "on #{os}" do
        let(:facts) do
          facts.merge (
            {
              :virtual       => 'vmware',
              :puppetversion => Puppet.version
            }
          )
        end

        describe 'tools_version => 3.5u3' do
          let(:params) do
            {
              :tools_version => '3.5u3'
            }
          end

          it do
            is_expected.to contain_class('vmwaretools::repo').with(
              'tools_version' => '3.5u3'
            )
            is_expected.to contain_package('vmware-tools-nox')
            is_expected.to contain_service('vmware-tools').with(
              'pattern' => 'vmware-guestd'
            )
          end
        end

        describe 'tools_version => 4.0u4' do
          let(:params) do
            {
              :tools_version => '4.0u4'
            }
          end

          it do
            is_expected.to contain_class('vmwaretools::repo').with(
              'tools_version' => '4.0u4'
            )
            is_expected.to contain_package('vmware-tools-nox')
            is_expected.to contain_service('vmware-tools').with(
              'pattern' => 'vmware-guestd'
            )
          end
        end

        describe 'tools_version => 4.1' do
          let(:params) do
            {
              :tools_version => '4.1'
            }
          end

          it do
            is_expected.to contain_class('vmwaretools::repo').with(
              'tools_version' => '4.1'
            )
            is_expected.to contain_package('vmware-tools-nox')
            is_expected.to contain_service('vmware-tools').with(
              'pattern' => 'vmtoolsd'
            )
          end
        end

        case facts[:osfamily]
        when 'RedHat'
          describe 'tools_version => 5.0' do
            let(:params) do
              {
                :tools_version => '5.0'
              }
            end

            it do
              is_expected.to contain_class('vmwaretools::repo').with(
                'tools_version' => '5.0'
              )
              is_expected.to contain_package('vmware-tools-esx-nox')
              is_expected.to contain_package('vmware-tools-esx-kmods')
              is_expected.to contain_service('vmware-tools-services').with(
                'pattern' => 'vmtoolsd'
              )
              is_expected.not_to contain_service('vmware-tools-services').with(
                'start' => '/sbin/start vmware-tools-services'
              )
            end
          end

          describe 'tools_version => 5.1' do
            let(:params) do
              {
                :tools_version => '5.1'
              }
            end

            it do
              is_expected.to contain_class('vmwaretools::repo').with(
                'tools_version' => '5.1'
              )
              is_expected.to contain_package('vmware-tools-esx-nox')
              is_expected.to contain_package('vmware-tools-esx-kmods')
              case facts[:operatingsystemmajrelease]
              when '6'
                is_expected.to contain_service('vmware-tools-services')
                is_expected.not_to contain_service('vmware-tools')
              else
                is_expected.not_to contain_service('vmware-tools')
                is_expected.to contain_service('vmware-tools-services').with(
                  'pattern' => 'vmtoolsd'
                )
              end
            end
          end

          describe 'tools_version => 5.5p02' do
            let(:params) do
              {
                :tools_version => '5.5p02'
              }
            end

            it do
              is_expected.to contain_class('vmwaretools::repo').with(
                'tools_version' => '5.5p02'
              )
              is_expected.to contain_package('vmware-tools-esx-nox')
              is_expected.to contain_package('vmware-tools-esx-kmods')
              is_expected.not_to contain_service('vmware-tools')
              case facts[:operatingsystemmajrelease]
              when '6'
                is_expected.to contain_service('vmware-tools-services')
              else
                is_expected.to contain_service('vmware-tools-services').with(
                  'pattern' => 'vmtoolsd'
                )
              end
            end
          end
        when 'SuSE'
          describe 'tools_version => 5.1 and operatingsystem => SLES' do
            let(:params) do
              {
                :tools_version => '5.1'
              }
            end

            it do
              is_expected.to contain_class('vmwaretools::repo').with(
                'tools_version' => '5.1'
              )
              is_expected.to contain_package('vmware-tools-esx-nox')
              is_expected.to contain_package('vmware-tools-esx-kmods-default')
              is_expected.to contain_service('vmware-tools-services').with(
                'pattern' => 'vmtoolsd'
              )
              is_expected.not_to contain_service('vmware-tools-services').with(
                'start' => '/sbin/start vmware-tools-services'
              )
            end
          end
        end

        describe 'disable_tools_version => false' do
          let(:params) do
            {
              :disable_tools_version => false
            }
          end

          it do
            is_expected.to contain_file_line('disable-tools-version').with(
              'path' => '/etc/vmware-tools/tools.conf',
              'line' => 'disable-tools-version = "false"'
            )
          end
        end

        describe 'manage_repository => false' do
          let(:params) do
            {
              :manage_repository => false
            }
          end

          it do
            is_expected.not_to contain_class('vmwaretools::repo')
          end
        end

        describe 'ensure => absent' do
          let(:params) do
            {
              :ensure => 'absent'
            }
          end

          case facts[:osfamily]
          when 'RedHat'
            it do
              is_expected.to contain_class('vmwaretools::repo').with_ensure('absent')
              is_expected.to contain_package('vmware-tools-esx-nox').with_ensure('absent')
              is_expected.to contain_package('vmware-tools-esx-kmods').with_ensure('absent')
              is_expected.to contain_file_line('disable-tools-version')
              is_expected.to contain_service('vmware-tools-services').with_ensure('stopped')
            end
          when 'SuSE'
            it do
              is_expected.to contain_class('vmwaretools::repo').with_ensure('absent')
              is_expected.to contain_package('vmware-tools-esx-nox').with_ensure('absent')
              is_expected.to contain_package('vmware-tools-esx-kmods-default').with_ensure('absent')
              is_expected.to contain_file_line('disable-tools-version')
              is_expected.to contain_service('vmware-tools-services').with_ensure('stopped')
            end
          when 'Debian'
            it do
              is_expected.to contain_class('vmwaretools::repo').with_ensure('absent')
              is_expected.to contain_package('vmware-tools-esx-nox').with_ensure('absent')
              is_expected.to contain_package('vmware-tools-esx-kmods-3.8.0-29-generic').with_ensure('absent')
              is_expected.to contain_file_line('disable-tools-version')
              is_expected.to contain_service('vmware-tools-services').with_ensure('stopped')
            end
          end
        end
      end
    end
  end
end
