require 'spec_helper'

describe 'vmwaretools::repo', :type => 'class' do
  context 'on a non-supported osfamily' do
    let :facts do
      {
        :osfamily                  => 'foo',
        :operatingsystem           => 'foo',
        :operatingsystemrelease    => '1.0',
        :operatingsystemmajrelease => '1',
        :virtual                   => 'foo'
      }
    end

    it do
      is_expected.not_to contain_yumrepo('vmware-tools')
    end

    it do
      is_expected.not_to contain_file('/etc/yum.repos.d/vmware-tools.repo')
    end

    it do
      is_expected.not_to contain_zypprepo('vmware-tools')
    end

    it do
      is_expected.not_to contain_file('/etc/zypp/repos.d/vmware-tools.repo')
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
          is_expected.not_to contain_yumrepo('vmware-tools')
        end

        it do
          is_expected.not_to contain_file('/etc/yum.repos.d/vmware-tools.repo')
        end

        it do
          is_expected.not_to contain_zypprepo('vmware-tools')
        end

        it do
          is_expected.not_to contain_file('/etc/zypp/repos.d/vmware-tools.repo')
        end

        it do
          is_expected.not_to contain_apt__source('vmware-tools')
        end
      end
    end
  end

  context 'on a supported osfamily, vmware platform, default parameters' do
    on_supported_os.each do |os,facts|
      context "on #{os}" do
        let(:facts) do
          facts.merge (
            {
              :virtual => 'vmware'
            }
          )
        end

        case facts[:operatingsystem]
        when 'RedHat', 'CentOS', 'Scientific', 'OracleLinux', 'OEL'
          it do
            is_expected.to contain_yumrepo('vmware-tools').with(
              :descr           => "VMware Tools latest - rhel#{facts[:operatingsystemmajrelease]} #{facts[:architecture]}",
              :enabled         => '1',
              :gpgcheck        => '1',
              :gpgkey          => "http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-DSA-KEY.pub\n    http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub",
              :baseurl         => "http://packages.vmware.com/tools/esx/latest/rhel#{facts[:operatingsystemmajrelease]}/#{facts[:architecture]}/",
              :priority        => '50',
              :protect         => '0',
              :proxy           => 'absent',
              :proxy_username  => 'absent',
              :proxy_password  => 'absent'
            )
          end

          it do
            is_expected.to contain_file('/etc/yum.repos.d/vmware-tools.repo')
          end
        when 'SLES', 'SLED'
          it do
            is_expected.to contain_zypprepo('vmware-tools').with(
              :descr       => "VMware Tools latest - sles#{facts[:operatingsystemrelease]} #{facts[:architecture]}",
              :enabled     => '1',
              :gpgcheck    => '1',
              :gpgkey      => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
              :baseurl     => "http://packages.vmware.com/tools/esx/latest/sles#{facts[:operatingsystemrelease]}/#{facts[:architecture]}/",
              :priority    => '50',
              :autorefresh => '1',
              :notify      => 'Exec[vmware-import-gpgkey]'
            )
          end

          it do
            is_expected.to contain_file('/etc/zypp/repos.d/vmware-tools.repo')
          end

          it do
            is_expected.to contain_exec('vmware-import-gpgkey')
          end
        when 'Ubuntu'
          let(:pre_condition) { "class { 'apt': }" }

          it do
            is_expected.to contain_apt__source('vmware-tools').with(
              :comment    => "VMware Tools latest - ubuntu #{facts[:lsbdistcodename]}",
              :ensure     => 'present',
              :location   => 'http://packages.vmware.com/tools/esx/latest/ubuntu',
              :key_source => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
              :key        => '36E47E1CC4DCC5E8152D115CC0B5E0AB66FD4949'
            )
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
                :virtual => 'vmware'
              }
            )
          end

          case facts[:operatingsystem]
          when 'RedHat', 'CentOS', 'Scientific', 'OracleLinux', 'OEL'

            describe 'tools_version => 5.1' do
              let(:params) {{ :tools_version => '5.1' }}
              it do
                is_expected.to contain_yumrepo('vmware-tools').with(
                  :descr    => "VMware Tools 5.1 - rhel#{facts[:operatingsystemmajrelease]} #{facts[:architecture]}",
                  :gpgkey   => "http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-DSA-KEY.pub\n    http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub",
                  :baseurl  => "http://packages.vmware.com/tools/esx/5.1/rhel#{facts[:operatingsystemmajrelease]}/#{facts[:architecture]}/"
                )
              end
            end

            describe 'ensure => absent' do
              let(:params) do
                {
                  :ensure => 'absent'
                }
              end

              it do
                is_expected.to contain_yumrepo('vmware-tools').with_enabled('0')
              end
            end

            describe 'reposerver => http://localhost:8000' do
              let(:params) do
                {
                  :reposerver => 'http://localhost:8000'
                }
              end

              it do
                is_expected.to contain_yumrepo('vmware-tools').with(
                  :gpgkey   => "http://localhost:8000/tools/keys/VMWARE-PACKAGING-GPG-DSA-KEY.pub\n    http://localhost:8000/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub",
                  :baseurl  => "http://localhost:8000/tools/esx/latest/rhel#{facts[:operatingsystemmajrelease]}/#{facts[:architecture]}/"
                )
              end
            end

            describe 'repopath => /some/path' do
              let(:params) do
                {
                  :repopath => '/some/path'
                }
              end

              it do
                is_expected.to contain_yumrepo('vmware-tools').with(
                  :gpgkey   => "http://packages.vmware.com/some/path/VMWARE-PACKAGING-GPG-DSA-KEY.pub\n    http://packages.vmware.com/some/path/VMWARE-PACKAGING-GPG-RSA-KEY.pub",
                  :baseurl  => 'http://packages.vmware.com/some/path/'
                )
              end
            end

            describe 'gpgkey_url => http://localhost:8000/custom/path/' do
              let(:params) do
                {
                  :gpgkey_url => 'http://localhost:8000/custom/path/'
                }
              end

              it do
                is_expected.to contain_yumrepo('vmware-tools').with(
                  :gpgkey => "http://localhost:8000/custom/path/VMWARE-PACKAGING-GPG-DSA-KEY.pub\n    http://localhost:8000/custom/path/VMWARE-PACKAGING-GPG-RSA-KEY.pub"
                )
              end
            end

            describe 'reposerver => http://localhost:8000 and repopath => /some/path' do
              let :params do
                {
                  :reposerver => 'http://localhost:8000',
                  :repopath   => '/some/path'
                }
              end

              it do
                is_expected.to contain_yumrepo('vmware-tools').with(
                  :gpgkey   => "http://localhost:8000/some/path/VMWARE-PACKAGING-GPG-DSA-KEY.pub\n    http://localhost:8000/some/path/VMWARE-PACKAGING-GPG-RSA-KEY.pub",
                  :baseurl  => 'http://localhost:8000/some/path/'
                )
              end
            end

            describe 'reposerver => http://localhost:8000 and repopath => /some/path and just_prepend_repopath => true' do
              let :params do
                {
                  :reposerver            => 'http://localhost:8000',
                  :repopath              => '/some/path',
                  :just_prepend_repopath => true
                }
              end

              it do
                is_expected.to contain_yumrepo('vmware-tools').with(
                  :gpgkey   => "http://localhost:8000/some/path/keys/VMWARE-PACKAGING-GPG-DSA-KEY.pub\n    http://localhost:8000/some/path/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub",
                  :baseurl  => "http://localhost:8000/some/path/esx/latest/rhel#{facts[:operatingsystemmajrelease]}/#{facts[:architecture]}/"
                )
              end
            end

            describe 'proxy => http://proxy:8080/' do
              let :params do
                {
                  :proxy => 'http://proxy:8080/'
                }
              end

              it do
                is_expected.to contain_yumrepo('vmware-tools').with(
                  :proxy => 'http://proxy:8080/'
                )
              end
            end

            describe 'proxy_username => someuser' do
              let :params do
                {
                  :proxy_username => 'someuser'
                }
              end

              it do
                is_expected.to contain_yumrepo('vmware-tools').with(
                  :proxy_username => 'someuser'
                )
              end
            end

            describe 'proxy_password => somepasswd' do
              let :params do
                {
                  :proxy_password => 'somepasswd'
                }
              end

              it do
                is_expected.to contain_yumrepo('vmware-tools').with(
                  :proxy_password => 'somepasswd'
                )
              end
            end
          end
        end
      end
    end
  end
end
