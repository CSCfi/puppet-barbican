#
# Copyright (C) 2016 Red Hat Inc. <licensing@redhat.com>
#
# Author: Ade Lee <alee@redhat.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Unit tests for barbican::api class
#
require 'spec_helper'

describe 'barbican::api' do

  shared_examples_for 'barbican api' do

    let :default_params do
      {
        :bind_host                                     => '0.0.0.0',
        :bind_port                                     => '9311',
        :default_transport_url                         => '<SERVICE DEFAULT>',
        :rpc_response_timeout                          => '<SERVICE DEFAULT>',
        :control_exchange                              => '<SERVICE DEFAULT>',
        :notification_transport_url                    => '<SERVICE DEFAULT>',
        :notification_driver                           => '<SERVICE DEFAULT>',
        :notification_topics                           => '<SERVICE DEFAULT>',
        :rabbit_use_ssl                                => '<SERVICE DEFAULT>',
        :rabbit_heartbeat_timeout_threshold            => '<SERVICE DEFAULT>',
        :rabbit_heartbeat_rate                         => '<SERVICE DEFAULT>',
        :rabbit_heartbeat_in_pthread                   => '<SERVICE DEFAULT>',
        :rabbit_ha_queues                              => '<SERVICE DEFAULT>',
        :amqp_durable_queues                           => '<SERVICE DEFAULT>',
        :max_allowed_secret_in_bytes                   => '<SERVICE DEFAULT>',
        :max_allowed_request_size_in_bytes             => '<SERVICE DEFAULT>',
        :enable_queue                                  => '<SERVICE DEFAULT>',
        :queue_namespace                               => '<SERVICE DEFAULT>',
        :queue_topic                                   => '<SERVICE DEFAULT>',
        :queue_version                                 => '<SERVICE DEFAULT>',
        :queue_server_name                             => '<SERVICE DEFAULT>',
        :kombu_ssl_ca_certs                            => '<SERVICE DEFAULT>',
        :kombu_ssl_certfile                            => '<SERVICE DEFAULT>',
        :kombu_ssl_keyfile                             => '<SERVICE DEFAULT>',
        :kombu_ssl_version                             => '<SERVICE DEFAULT>',
        :kombu_reconnect_delay                         => '<SERVICE DEFAULT>',
        :kombu_failover_strategy                       => '<SERVICE DEFAULT>',
        :manage_service                                => true,
        :enabled                                       => true,
        :enabled_secretstore_plugins                   => ['<SERVICE DEFAULT>'],
        :enabled_crypto_plugins                        => ['<SERVICE DEFAULT>'],
        :enabled_certificate_plugins                   => ['<SERVICE DEFAULT>'],
        :enabled_certificate_event_plugins             => ['<SERVICE DEFAULT>'],
        :auth_strategy                                 => 'keystone',
        :retry_scheduler_initial_delay_seconds         => '<SERVICE DEFAULT>',
        :retry_scheduler_periodic_interval_max_seconds => '<SERVICE DEFAULT>',
        :service_name                                  => platform_params[:service_name],
        :enable_proxy_headers_parsing                  => '<SERVICE DEFAULT>',
        :max_request_body_size                         => '<SERVICE DEFAULT>',
        :multiple_secret_stores_enabled                => false,
        :enabled_secret_stores                         => 'simple_crypto',
      }
    end

    [{
        :bind_host                                     => '127.0.0.1',
        :bind_port                                     => '9312',
        :default_transport_url                         => 'rabbit://bugs:bugs_bunny@localhost:1234/rabbithost',
        :rpc_response_timeout                          => '120',
        :control_exchange                              => 'barbican',
        :notification_transport_url                    => 'rabbit://bugs:bugs_bunny@localhost:1234/rabbithost',
        :notification_driver                           => 'kombu',
        :notification_topics                           => 'notifications',
        :rabbit_use_ssl                                => true,
        :rabbit_heartbeat_timeout_threshold            => '10',
        :rabbit_heartbeat_rate                         => '10',
        :rabbit_heartbeat_in_pthread                   => true,
        :rabbit_ha_queues                              => true,
        :amqp_durable_queues                           => true,
        :enable_queue                                  => true,
        :queue_namespace                               => 'barbican1',
        :queue_topic                                   => 'barbican1.workers',
        :queue_version                                 => '1.2',
        :queue_server_name                             => 'barbican1.queue',
        :manage_service                                => true,
        :enabled                                       => false,
        :kombu_ssl_ca_certs                            => 'path_to_certs',
        :kombu_ssl_certfile                            => 'path_to_certfile',
        :kombu_ssl_keyfile                             => 'path_to_keyfile',
        :kombu_ssl_version                             => '1.2',
        :kombu_reconnect_delay                         => '10',
        :kombu_failover_strategy                       => 'shuffle',
        :enabled_secretstore_plugins                   => ['dogtag_crypto', 'store_crypto', 'kmip'],
        :enabled_crypto_plugins                        => ['simple_crypto'],
        :enabled_certificate_plugins                   => ['simple_certificate', 'dogtag'],
        :enabled_certificate_event_plugins             => ['simple_certificate_event', 'foo_event'],
        :retry_scheduler_initial_delay_seconds         => 20.0,
        :retry_scheduler_periodic_interval_max_seconds => 20.0,
        :max_allowed_secret_in_bytes                   => 20000,
        :max_allowed_request_size_in_bytes             => 2000000,
        :enable_proxy_headers_parsing                  => false,
        :max_request_body_size                         => '102400',
        :multiple_secret_stores_enabled                => true,
        :enabled_secret_stores                         => 'simple_crypto,dogtag,kmip',
      }
    ].each do |param_set|
      describe "when #{param_set == {} ? "using default" : "specifying"} class parameters" do
        let :pre_condition do
          'class { "barbican::keystone::authtoken": password => "secret", }
          include ::apache'
        end

        let :param_hash do
          default_params.merge(param_set)
        end

        let :params do
          default_params.merge(param_set)
        end

        let :host_ref do
          "http://${::fqdn}:$param_hash[:bind_port]"
        end

        it { is_expected.to contain_class('barbican::deps') }
        it { is_expected.to contain_class('barbican::db') }
        it { is_expected.to contain_class('barbican::policy') }

        it { is_expected.to contain_package('barbican-api').with(
            :tag => ['openstack', 'barbican-package'],
         )}

        it 'is_expected.to set default parameters' do
          [
            'bind_host',
            'bind_port',
            'max_allowed_secret_in_bytes',
            'max_allowed_request_size_in_bytes',
          ].each do |config|
            is_expected.to contain_barbican_config("DEFAULT/#{config}").with_value(param_hash[config.intern])
          end
        end

        it 'configures queue' do
          is_expected.to contain_barbican_config('queue/enable').with_value(param_hash[:enable_queue])
          is_expected.to contain_barbican_config('queue/namespace').with_value(param_hash[:queue_namespace])
          is_expected.to contain_barbican_config('queue/topic').with_value(param_hash[:queue_topic])
          is_expected.to contain_barbican_config('queue/version').with_value(param_hash[:queue_version])
          is_expected.to contain_barbican_config('queue/server_name').with_value(param_hash[:queue_server_name])
        end

        it 'configures rabbit' do
          is_expected.to contain_barbican_config('DEFAULT/transport_url').with_value(param_hash[:default_transport_url])
          is_expected.to contain_barbican_config('DEFAULT/rpc_response_timeout').with_value(param_hash[:rpc_response_timeout])
          is_expected.to contain_barbican_config('DEFAULT/control_exchange').with_value(param_hash[:control_exchange])
          is_expected.to contain_barbican_config('oslo_messaging_notifications/transport_url').with_value(param_hash[:notification_transport_url])
          is_expected.to contain_barbican_config('oslo_messaging_notifications/driver').with_value(param_hash[:notification_driver])
          is_expected.to contain_barbican_config('oslo_messaging_notifications/topics').with_value(param_hash[:notification_topics])
          is_expected.to contain_barbican_config('oslo_messaging_rabbit/heartbeat_timeout_threshold').with_value(param_hash[:rabbit_heartbeat_timeout_threshold])
          is_expected.to contain_barbican_config('oslo_messaging_rabbit/heartbeat_rate').with_value(param_hash[:rabbit_heartbeat_rate])
          is_expected.to contain_barbican_config('oslo_messaging_rabbit/heartbeat_in_pthread').with_value(param_hash[:rabbit_heartbeat_in_pthread])
          is_expected.to contain_oslo__messaging__rabbit('barbican_config').with(
            :rabbit_use_ssl     => true,
            :kombu_ssl_ca_certs => 'path_to_certs',
            :kombu_ssl_certfile => 'path_to_certfile',
            :kombu_ssl_keyfile  => 'path_to_keyfile',
            :kombu_ssl_version  => '1.2',
          )
        end

        it 'configures kombu params' do
          is_expected.to contain_barbican_config('oslo_messaging_rabbit/kombu_reconnect_delay').with_value(param_hash[:kombu_reconnect_delay])
          is_expected.to contain_barbican_config('oslo_messaging_rabbit/kombu_failover_strategy').with_value(param_hash[:kombu_failover_strategy])
        end

        it 'configures enabled plugins' do
          is_expected.to contain_barbican_config('secretstore/enabled_secretstore_plugins') \
            .with_value(param_hash[:enabled_secretstore_plugins])
          is_expected.to contain_barbican_config('crypto/enabled_crypto_plugins') \
            .with_value(param_hash[:enabled_crypto_plugins])
          is_expected.to contain_barbican_config('certificate/enabled_certificate_plugins') \
            .with_value(param_hash[:enabled_certificate_plugins])
          is_expected.to contain_barbican_config('certificate_event/enabled_certificate_event_plugins') \
            .with_value(param_hash[:enabled_certificate_event_plugins])
        end

        it 'configures plugins in multiple plugin config' do
          is_expected.to contain_barbican_config('secretstore/stores_lookup_suffix') \
            .with_value(param_hash[:enabled_secret_stores])
          is_expected.to contain_barbican_config('secretstore/enable_multiple_secret_stores') \
            .with_value(param_hash[:multiple_secret_stores_enabled])
        end
      end
    end

    describe 'with enable_proxy_headers_parsing' do
      let :pre_condition do
        'class { "barbican::keystone::authtoken": password => "secret", }
        include ::apache'
      end

      let :params do
        default_params.merge!({:enable_proxy_headers_parsing => true })
      end

      it { is_expected.to contain_oslo__middleware('barbican_config').with(
        :enable_proxy_headers_parsing => true,
      )}
    end

    describe 'with max_request_body_size' do
      let :pre_condition do
        'class { "barbican::keystone::authtoken": password => "secret", }
        include ::apache'
      end

      let :params do
        default_params.merge!({:max_request_body_size => '102400' })
      end

      it { is_expected.to contain_oslo__middleware('barbican_config').with(
        :max_request_body_size => '102400',
      )}
    end

    describe 'with SSL socket options set' do
      let :pre_condition do
          'class { "barbican::keystone::authtoken": password => "secret", }
           include ::apache'
      end

      let :params do
        default_params.merge({
          :use_ssl   => true,
          :cert_file => '/path/to/cert',
          :ca_file   => '/path/to/ca',
          :key_file  => '/path/to/key',
        })
      end

      it { is_expected.to contain_barbican_config('DEFAULT/ca_file').with_value('/path/to/ca') }
      it { is_expected.to contain_barbican_config('DEFAULT/cert_file').with_value('/path/to/cert') }
      it { is_expected.to contain_barbican_config('DEFAULT/key_file').with_value('/path/to/key') }
    end

    describe 'with SSL socket options left by default' do
      let :pre_condition do
          'class { "barbican::keystone::authtoken": password => "secret", }
           include ::apache'
      end

      let :params do
        default_params.merge({
          :use_ssl => false,
        })
      end

      it { is_expected.to contain_barbican_config('DEFAULT/ca_file').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_barbican_config('DEFAULT/cert_file').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_barbican_config('DEFAULT/key_file').with_value('<SERVICE DEFAULT>') }
    end

    describe 'with SSL socket options set wrongly configured' do
      let :pre_condition do
          'class { "barbican::keystone::authtoken": password => "secret", }
           include ::apache'
      end

      let :params do
        default_params.merge({
          :use_ssl  => true,
          :ca_file  => '/path/to/ca',
          :key_file => '/path/to/key',
        })
      end

      it_raises 'a Puppet::Error', /The cert_file parameter is required when use_ssl is set to true/
    end

    describe 'with keystone auth' do
      let :pre_condition do
          'class { "barbican::keystone::authtoken": password => "secret", }
           include ::apache'
      end

      let :params do
        default_params.merge({
          :auth_strategy => 'keystone',
        })
      end

      it 'is_expected.to set keystone params correctly' do
        is_expected.to contain_barbican_api_paste_ini('pipeline:barbican_api/pipeline')\
          .with_value('cors authtoken context apiapp')
        is_expected.to contain_class('barbican::keystone::authtoken')
      end
    end
  end

  shared_examples_for 'barbican api redhat' do
    let :param_hash do
      {
        :manage_service => true,
        :enabled        => true,
        :auth_strategy  => 'keystone',
      }
    end
    let :pre_condition do
      'class { "barbican::keystone::authtoken": password => "secret", }'
    end
    context 'redhat systems eventlet service enabled' do
      describe 'should contain eventlet service' do
        it { is_expected.to contain_service('barbican-api').with(
          'ensure'     => (param_hash[:manage_service] && param_hash[:enabled]) ? 'running': 'stopped',
          'enable'     => param_hash[:enabled],
          'hasstatus'  => true,
          'hasrestart' => true,
          'tag'        => 'barbican-service',
        ) }
      end
    end
    context 'on redhat systems eventlet service disabled' do
      describe 'with disabled service managing' do
        let :params do
          {
            :manage_service => false,
            :enabled        => false,
            :auth_strategy  => 'keystone',
          }
        end

        it { is_expected.to contain_service('barbican-api').with(
          'ensure'     => nil,
          'enable'     => false,
          'hasstatus'  => true,
          'hasrestart' => true,
          'tag'        => 'barbican-service',
        )}
      end
    end
  end

  on_supported_os({
    :supported_os   => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge(OSDefaults.get_facts({
          :processorcount => 7,
          :fqdn           => 'some.host.tld',
          :concat_basedir => '/var/lib/puppet/concat',
        }))
      end

      case facts[:osfamily]
      when 'RedHat'
        let (:platform_params) do
          { :service_name => 'barbican-api' }
        end
        it_behaves_like 'barbican api redhat'
      when 'Debian'
        let :pre_condition do
          'include ::apache'
        end
        let (:platform_params) do
          { :service_name => 'httpd' }
        end
      end

      it_behaves_like 'barbican api'
    end
  end
end
