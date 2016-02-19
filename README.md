# cfer-consul-cluster-cookbook

Uses [Cfer](https://github.com/seanedwards/cfer) to launch a self-bootstrapping Consul cluster into an AWS AutoScaling group.

To launch the cluster, run `rake converge`. This will prompt you for:

* A VPC ID
* A comma-separated list of Subnet IDs
* An EC2 Keypair name

* Review and modify [consul.rb](https://github.com/seanedwards/chef-cfer-consul-cluster/blob/master/consul.rb) before using this in production.

## Features

* New nodes automatically join the cluster.
* Autoscaling policies roll over servers one at a time when changing things like instance type.
* CloudFormation creation and updates will fail and roll back if there's a provisioning issue.
