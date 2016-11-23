include ::vmwaretools
include ::vmwaretools::ntp
$virtual_real = $::virtual ? {
  'vmware' => Class['vmwaretools::ntp'],
  default  => undef,
}
package { 'ntpd':
  ensure => 'present',
  notify => $virtual_real,
}
