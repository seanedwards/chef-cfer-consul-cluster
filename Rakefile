require 'cfer'
require 'highline'

task :default => [ :converge ]

task :config_aws, [:profile] do |t, args|
  Aws.config.update region: ENV['AWS_REGION'] || ask('AWS Region?') { |q| q.default = 'us-east-1' },
    credentials: Aws::SharedCredentials.new(profile_name: ENV['AWS_PROFILE'] || ask('AWS Profile?') { |q| q.default = 'default' })
end

task :converge => :config_aws do |t, args|
  Cfer.converge! 'consul',
    template: 'consul.rb',
    parameters: {
      VpcId: ask('VPC ID?') { |q| q.default = ENV['CONSUL_VPC_ID'] },
      Subnets: ask('Subnets? (comma-separated)') { |q| q.default = ENV['CONSUL_SUBNETS'] },
      KeyName: ask('EC2 Key Name?') { |q| q.default = ENV['CONSUL_EC2_KEY_NAME'] }
    },
    on_failure: 'DO_NOTHING',
    follow: true
end

task :generate => :config_aws do |t, args|
  Cfer.generate! 'consul.rb',
    pretty_print: true
end
