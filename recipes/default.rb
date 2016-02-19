package 'jq'
package 'awscli'

chef_gem 'aws-sdk'

# Consul requires an explicit bind address when running on EC2.
node.default[:consul][:config][:bind_addr] = node['ec2']['local_ipv4'] if node.attribute?('ec2')

include_recipe 'aws'
include_recipe 'consul::default'
include_recipe 'consul::client_gem'

consul_ui 'consul-ui' do
  owner node['consul']['service_user']
  group node['consul']['service_group']
  version node['consul']['version']
end

