#
# Cookbook Name:: scala-jenkins-infra
# Recipe:: _config-ebs
#
# Copyright 2014, Typesafe, Inc.
#
# All rights reserved - Do Not Redistribute
#

include_recipe "aws"

# on non-AmazonLinux instances (e.g., ubuntu), convince ohai to check we're on ohai as follows:
# `sudo mkdir -p /etc/chef/ohai/hints/ && sudo touch /etc/chef/ohai/hints/ec2.json`
if node[:ec2]
  node['ebs']['volumes'].each do |mountPoint, ebsConfig|
    aws_ebs_volume ebsConfig['dev'] do
      size    ebsConfig['size']
      device  ebsConfig['dev']

      volume_type "gp2"
      availability_zone node[:ec2][:placement_availability_zone]
      action [:create, :attach]
    end

    case node["platform_family"]
    when "windows"
      force="" # set to "NOERR" to force partitioning&formatting the disk
      diskpartScript=<<-EOX.gsub(/^    /, '')
      select disk #{ebsConfig['disk']}
      attributes disk clear readonly
      online disk #{force}
      create partition primary #{force}
      select partition 1
      format FS=#{ebsConfig['fstype']} quick
      assign LETTER=#{mountPoint}
      EOX
      script "setupdisk" do
        interpreter "diskpart"
        flags "/s"
        code diskpartScript
        not_if { ::File.directory?("#{mountPoint}:\\") }
      end
    else
      device = node[:platform_family] == 'debian' ? ebsConfig['dev'].gsub(%r{^/dev/sd}, '/dev/xvd') : ebsConfig['dev']

      execute 'mkfs' do
        command "mkfs -t #{ebsConfig['fstype']} #{device}"
        not_if do
          BlockDevice.wait_for(device)
          system("blkid -s TYPE -o value #{device}")
        end
      end

      # workaround for when user doesn't exist during bootstrap
#      user ebsConfig['user'] do
#      end

      directory mountPoint do
        owner ebsConfig['user']
        mode 0755

        action :create
      end

      mount mountPoint do
        device  device
        fstype  ebsConfig['fstype']
        options ebsConfig['mountopts']

        action [:mount, :enable]
      end
    end
  end
end