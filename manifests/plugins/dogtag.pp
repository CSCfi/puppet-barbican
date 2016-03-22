# == Class: barbican::plugins::dogtag
#
# Sets up Barbican API dogtag secret_store and certificate plugin
#
# === Parameters
#
# [*dogtag_plugin_pem_path*]
#   (optional) Path to KRA agent PEM file
#   Defaults to $::os_service_default
#
# [*dogtag_plugin_dogtag_host*]
#   (optional) Host for the Dogtag server
#   Defaults to $::os_service_default
#
# [*dogtag_plugin_dogtag_port*]
#   (optional) Host for the Dogtag server
#   Defaults to $::os_service_default
#
# [*dogtag_plugin_nss_db_path*]
#   (optional) Path to plugin NSS DB
#   Defaults to $::os_service_default
#
# [*dogtag_plugin_nss_password*]
#   Password for plugin NSS DB
#   Defaults to undef
#
# [*dogtag_plugin_simple_cmc_profile*]
#   (optional) Profile for simple CMC enrollment.
#   Defaults to $::os_service_default
#
# [*dogtag_plugin_ca_expiration_time*]
#   (optional) Expiration time for the Dogtag CA entry in days
#   Defaults to $::os_service_default
#
# [*dogtag_plugin_plugin_working_dir*]
#   (optional) Working directory for Dogtag plugin
#   Defaults to $::os_service_default
#
class barbican::plugins::dogtag (
  $dogtag_plugin_pem_path           = $::os_service_default,
  $dogtag_plugin_dogtag_host        = $::os_service_default,
  $dogtag_plugin_dogtag_port        = $::os_service_default,
  $dogtag_plugin_nss_db_path        = $::os_service_default,
  $dogtag_plugin_nss_password       = undef,
  $dogtag_plugin_simple_cmc_profile = $::os_service_default,
  $dogtag_plugin_ca_expiration_time = $::os_service_default,
  $dogtag_plugin_plugin_working_dir = $::os_service_default,
) {

  include ::barbican::api

  if $dogtag_plugin_nss_password == undef {
    fail('dogtag_plugin_nss_password must be defined')
  }

  package {'dogtag-client':
    ensure => $::barbican::api::ensure_package,
    name   => $::barbican::params::dogtag_client_package,
    tag    => ['openstack', 'dogtag-client-package']
  } -> Service['barbican-api']

  barbican_config {
    'dogtag_plugin/pem_path':           value => $dogtag_plugin_pem_path;
    'dogtag_plugin/dogtag_host':        value => $dogtag_plugin_dogtag_host;
    'dogtag_plugin/dogtag_port':        value => $dogtag_plugin_dogtag_port;
    'dogtag_plugin/nss_db_path':        value => $dogtag_plugin_nss_db_path;
    'dogtag_plugin/nss_password':       value => $dogtag_plugin_nss_password;
    'dogtag_plugin/simple_cmc_profile': value => $dogtag_plugin_simple_cmc_profile;
    'dogtag_plugin/ca_expiration_time': value => $dogtag_plugin_ca_expiration_time;
    'dogtag_plugin/plugin_working_dir': value => $dogtag_plugin_plugin_working_dir;
  }
}
