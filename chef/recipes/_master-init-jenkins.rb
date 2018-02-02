#
# Cookbook Name:: scala-jenkins-infra
# Recipe:: _master-init-jenkins
#
# Copyright 2015, Typesafe, Inc.
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'jenkins::master'

# recursive doesn't set owner correctly??
directory "#{node['jenkins']['master']['home']}/users" do
  user node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
end

directory "#{node['jenkins']['master']['home']}/users/chef/" do
  user node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
end


# NOTE: the following attributes must be configured thusly (jenkins-cli comms will stay in the VPC)
#   see also on the workers: `node.set['jenkins']['master']['endpoint'] = "http://#{jenkinsMaster.ipaddress}:#{jenkinsMaster.jenkins.master.port}"`
# under jenkins.master
    # host: localhost
    # listen_address: 0.0.0.0
    # port: 8080
    # endpoint: http://localhost:8080
# keep endpoint at localhost (stay in VPC), must set this for reverse proxy to work
template "#{node['jenkins']['master']['home']}/jenkins.model.JenkinsLocationConfiguration.xml" do
  source 'jenkins.model.JenkinsLocationConfiguration.xml.erb'
  user node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
end

# this is to allow plugin installation using jenkins-cli (needs to use REST to download update center json)
cookbook_file "jenkins.model.DownloadSettings.xml" do
  path "#{node['jenkins']['master']['home']}/jenkins.model.DownloadSettings.xml"
  user  node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
end


