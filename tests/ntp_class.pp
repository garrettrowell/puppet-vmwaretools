class { '::vmwaretools':
  tools_version => '4.0',
  autoupgrade   => true,
}
class { '::vmwaretools::ntp': }
$virtual_real = $::virtual ? {
  'vmware'    => Class['vmwaretools::ntp'],
  default => undef,
}
package { 'ntpd':
  ensure => 'present',
  notify => $virtual_real,
}
