require 'spec_helper'

describe Chef::Resource::AwsSubnet do
  extend AWSSupport

  when_the_chef_12_server "exists", organization: 'foo', server_scope: :context do
    with_aws "with a VPC with an internet gateway, route table and network acl" do
      aws_vpc "test_vpc" do
        cidr_block '10.0.0.0/24'
        internet_gateway true
      end

      aws_route_table 'test_route_table' do
        vpc 'test_vpc'
      end

      aws_network_acl 'test_network_acl' do
        vpc 'test_vpc'
      end

      it "aws_subnet 'test_subnet' with no parameters except VPC creates a route table" do
        expect_recipe {
          aws_subnet 'test_subnet' do
            vpc 'test_vpc'
          end
        }.to create_an_aws_subnet('test_subnet',
          vpc_id: test_vpc.aws_object.id,
          cidr_block: test_vpc.aws_object.cidr_block
        ).and be_idempotent
      end

      it "aws_subnet 'test_subnet' with all parameters creates a route table" do
        az = driver.ec2.availability_zones.first.name
        expect_recipe {
          aws_subnet 'test_subnet' do
            vpc 'test_vpc'
            cidr_block '10.0.0.0/24'
            availability_zone az
            map_public_ip_on_launch true
            route_table 'test_route_table'
            network_acl 'test_network_acl'
          end
        }.to create_an_aws_subnet('test_subnet',
          vpc_id: test_vpc.aws_object.id,
          cidr_block: '10.0.0.0/24',
          'availability_zone.name' => az,
          'route_table.id' => test_route_table.aws_object.id,
          'network_acl.id' => test_network_acl.aws_object.id
        ).and be_idempotent
      end
    end
  end
end
