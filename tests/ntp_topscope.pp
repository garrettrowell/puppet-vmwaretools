$vmwaretools_tools_version = '4.1'
$vmwaretools_autoupgrade = true
include '::vmwaretools'
include '::vmwaretools::ntp'
$virtual_real = $::virtual ? {
  'vmware'    => Class['vmwaretools::ntp'],
  default => undef,
}
package { 'ntpd':
  ensure => 'present',
  notify => $virtual_real,
}
