#
# Cookbook Name:: memcached
# resource:: instance_sysv_init
#
# Copyright 2016, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

provides :memcached_instance_sysv_init

provides :memcached_instance, platform: 'amazon'

provides :memcached_instance, platform: %w(redhat centos scientific oracle) do |node| # ~FC005
  node['platform_version'].to_f < 7.0
end

provides :memcached_instance, platform: 'debian' do |node|
  node['platform_version'].to_i < 8
end

property :instance_name, String, name_attribute: true
property :memory, [Integer, String], default: 64
property :port, [Integer, String], default: 11_211
property :udp_port, [Integer, String], default: 11_211
property :listen, String, default: '0.0.0.0'
property :maxconn, [Integer, String], default: 1024
property :user, String, default: lazy { service_user }
property :threads, [Integer, String]
property :max_object_size, String, default: '1m'
property :experimental_options, Array, default: []
property :ulimit, [Integer, String], default: 1024
property :template_cookbook, String, default: 'memcached'
property :disable_default_instance, [TrueClass, FalseClass], default: true
property :remove_default_config, [TrueClass, FalseClass], default: true

action :start do
  create_init

  service memcached_instance_name do
    supports restart: true, status: true
    action :start
  end
end

action :stop do
  service memcached_instance_name do
    supports status: true
    action :stop
    only_if { ::File.exist?("/etc/init.d/#{memcached_instance_name}") }
  end
end

action :restart do
  action_stop
  action_start
end

action :enable do
  create_init

  service memcached_instance_name do
    supports status: true
    action :enable
    only_if { ::File.exist?("/etc/init.d/#{memcached_instance_name}") }
  end
end

action :disable do
  service memcached_instance_name do
    supports status: true
    action :disable
    only_if { ::File.exist?("/etc/init.d/#{memcached_instance_name}") }
  end
end

action_class.class_eval do
  def create_init
    include_recipe 'memcached::_package'

    # remove any runit instances with the same name if they exist
    disable_legacy_runit_instance

    # Disable the default memcached service to avoid port conflicts + wasted memory
    disable_default_memcached_instance

    # cleanup default configs to avoid confusion
    remove_default_memcached_configs

    # service resource for notification
    service memcached_instance_name do
      action :nothing
    end

    # the init script will not run without redhat-lsb packages
    package lsb_package if node['platform_family'] == 'rhel'

    template "/etc/init.d/#{memcached_instance_name}" do
      mode '0755'
      source 'init_sysv.erb'
      cookbook 'memcached'
      variables(
        lock_dir: lock_dir,
        instance: memcached_instance_name,
        ulimit: new_resource.ulimit,
        cli_options: cli_options
      )
      notifies :restart, "service[#{memcached_instance_name}]", :immediately
    end
  end
end
