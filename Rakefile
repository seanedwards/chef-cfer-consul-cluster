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
      VpcId: 'vpc-91c39cf5',
      Subnets: 'subnet-0fee3557,subnet-232cfa09',
      KeyName: 'MacBookAir'
    },
    on_failure: 'DO_NOTHING',
    follow: true
end

task :generate => :config_aws do |t, args|
  Cfer.generate! 'consul.rb',
    pretty_print: true
end
