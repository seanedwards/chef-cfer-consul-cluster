default[:consul][:config][:server] = true
default[:consul][:config][:bind_addr] = default['ec2'].attribute?('local_ipv4') ? default['ec2']['local_ipv4'] : '0.0.0.0'

