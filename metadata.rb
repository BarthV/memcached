name              'memcached'
maintainer        'Chef Software, Inc.'
maintainer_email  'cookbooks@chef.io'
license           'Apache 2.0'
description       'Installs memcached and includes memcached_instance resource for setting up runit memcached instances'
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           '2.1.0'

depends           'runit', '~> 1.0'
depends           'yum-epel'
depends           'compat_resource', '>= 12.9.0'

%w(ubuntu debian redhat centos suse scientific oracle amazon ).each do |os|
  supports os
end

recipe 'memcached::default', 'Installs and configures memcached'

source_url 'https://github.com/chef-cookbooks/memcached' if respond_to?(:source_url)
issues_url 'https://github.com/chef-cookbooks/memcached/issues' if respond_to?(:issues_url)
