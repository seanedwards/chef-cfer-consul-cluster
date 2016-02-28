description 'Fully-functional self-bootstrapping Consul cluster in an autoscaling group'

parameter :VpcId

# This is the Ubuntu 14.04 LTS HVM AMI provided by Amazon.
parameter :ImageId, default: 'ami-fce3c696'
parameter :InstanceType, default: 't2.nano'

parameter :Subnets, default: 'sg-asdf'

subnets = parameters[:Subnets].split(',')

parameter :NodeCount, default: subnets.size

resource :ConsulSG, "AWS::EC2::SecurityGroup" do
  group_description 'Security Group for Consul nodes'
  vpc_id Fn::ref(:VpcId)

  # Parameter values can be Ruby arrays and hashes. These will be transformed to JSON.
  # You could write your own functions to make stuff like this easier, too.
  security_group_ingress [
    {
      CidrIp: '0.0.0.0/0',
      IpProtocol: 'tcp',
      FromPort: 22,
      ToPort: 22
    }
  ]
end

resource :ConsulSGIngressAny, "AWS::EC2::SecurityGroupIngress" do
  group_id Fn::ref(:ConsulSG)
  source_security_group_id Fn::ref(:ConsulSG)
  ip_protocol '-1'
  from_port 0
  to_port 65536
end

resource :ConsulRole, "AWS::IAM::Role" do
  assume_role_policy_document Version: "2012-10-17",
    Statement: [ {
      Effect: "Allow",
      Principal: {
        Service: [ "ec2.amazonaws.com" ]
      },
      Action: [ "sts:AssumeRole" ]
    } ]

  policies [ {
    PolicyName: 'describe-ec2',
    PolicyDocument: {
      Version: "2012-10-17",
      Statement: [ {
          Effect: "Allow",
          Action: "ec2:DescribeInstances",
          Resource: "*"
      } ]
    }
  } ]

  path '/'
end

resource :ConsulInstanceProfile, "AWS::IAM::InstanceProfile" do
  path '/'
  roles [ Fn::ref(:ConsulRole) ]
end

resource :ConsulLaunchConfig, "AWS::AutoScaling::LaunchConfiguration" do
  cfn_init_setup signal: :ConsulASG,
    cfn_init_config_set: [ :cfn_hup, :install_chef, :run_chef, :bootstrap_consul ],
    cfn_hup_config_set: [ :cfn_hup, :run_chef ]

  chef_solo version: 'latest',
    node: {
      run_list: ['recipe[cfer-consul-cluster]'],
      consul: {
        config: {
          server: true,
          ui: true,
          bootstrap_expect: subnets.size
        }
      }
    },
    berksfile: <<-EOF
      source "https://supermarket.chef.io"

      cookbook 'cfer-consul-cluster', git: 'https://github.com/seanedwards/chef-cfer-consul-cluster.git'
    EOF

  cfn_init_config :bootstrap_consul do
    command :join_cluster, Fn::join('', [
      'aws --output json ec2 describe-instances',
        ' --region ', AWS::region,
        ' --filter',
          ' Name=iam-instance-profile.arn,Values=', Fn::get_att(:ConsulInstanceProfile, :Arn),
          ' Name=instance-state-name,Values=running',
        ' | jq -r \'.Reservations[].Instances[].PrivateIpAddress\'',
        ' | xargs consul join'
    ]),
    ignoreErrors: true
  end
  cfn_init_config_set :bootstrap_consul, [:bootstrap_consul]

  image_id Fn::ref(:ImageId)
  instance_type Fn::ref(:InstanceType)
  iam_instance_profile Fn::ref(:ConsulInstanceProfile)
  key_name 'MacBookAir'
  associate_public_ip_address true
  security_groups [ Fn::ref(:ConsulSG) ]
end

resource :ConsulASG, "AWS::AutoScaling::AutoScalingGroup",
  CreationPolicy: {
    ResourceSignal: {
      Count: subnets.size,
      Timeout: 'PT10M0S'
    }
  },
  UpdatePolicy: {
    AutoScalingRollingUpdate: {
      MinInstancesInService: subnets.size,
      MaxBatchSize: 1,
      PauseTime: 'PT10M0S',
      WaitOnResourceSignals: true
    }
  } do
  launch_configuration_name Fn::ref(:ConsulLaunchConfig)

  load_balancer_names [ Fn::ref(:ConsulELB) ] if parameters[:CreateELB] == 'true'

  max_size subnets.size + 1
  min_size subnets.size
  desired_capacity subnets.size

  properties :VPCZoneIdentifier => subnets
end

output :ConsulSG, Fn::ref(:ConsulSG)


parameter :CreateELB, default: 'true'

if parameters[:CreateELB] == 'true'

  resource :ConsulELBSG, "AWS::EC2::SecurityGroup" do
    group_description 'Security Group for Consul Load Balancer'
    vpc_id Fn::ref(:VpcId)

    security_group_ingress [
      {
        CidrIp: '0.0.0.0/0',
        IpProtocol: 'tcp',
        FromPort: 80,
        ToPort: 80
      }
    ]
  end

  resource :ConsulSGIngressELB, "AWS::EC2::SecurityGroupIngress" do
    group_id Fn::ref(:ConsulSG)
    source_security_group_id Fn::ref(:ConsulELBSG)
    ip_protocol 'tcp'
    from_port 8600
    to_port 8600
  end

  resource :ConsulELB, "AWS::ElasticLoadBalancing::LoadBalancer" do
    security_groups [ Fn::ref(:ConsulELBSG) ]
    properties :Subnets => subnets
    listeners [
      {
        InstancePort: 8600,
        LoadBalancerPort: 80,
        InstanceProtocol: 'HTTP',
        Protocol: 'HTTP'
      }
    ]
  end

  output :ConsulELBAddr, Fn::get_att(:ConsulELB, :DNSName)
  output :ConsulELBSG, Fn::ref(:ConsulELBSG)
end
