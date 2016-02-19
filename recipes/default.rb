#
# Cookbook Name:: cfer-consul-cluster
# Recipe:: default
#
# Copyright (C) 2016 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#

package 'jq'
package 'awscli'

chef_gem 'aws-sdk'

include_recipe 'aws'
include_recipe 'consul::default'
include_recipe 'consul::client_gem'

consul_ui 'consul-ui' do
  owner node['consul']['service_user']
  group node['consul']['service_group']
  version node['consul']['version']
end

