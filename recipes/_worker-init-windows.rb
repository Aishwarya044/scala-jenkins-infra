#
# Cookbook Name:: scala-jenkins-infra
# Recipe:: _worker-init-windows
#
# Copyright 2014, Typesafe, Inc.
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'windows'

# TODO: not idempotent (must stop jenkins slave service before re-installing jdk)
# hacked around by not re-installing java when javac of the right version is found
# needed for other stuff (install ruby etc)

def checkJavacVersion
  javac = File.join(node['java']['java_home'], "bin", "javac.exe")
  javacVersion = ""
  if File.exists?(javac)
    # http://stackoverflow.com/a/1666103/276895
    IO.popen(javac+" -version 2>&1") do |pipe| # Redirection is performed using operators
      pipe.sync = true
      while str = pipe.gets
        javacVersion = javacVersion + str # This is synchronous!
      end
    end
  end
  javacVersion.chop
end

include_recipe "java" if checkJavacVersion != node['java']['javacVersion']

ruby_block 'Add Embedded Bin Path' do
  block do
    ENV['PATH'] += ';C:/opscode/chef/embedded/bin'
  end
  action :nothing
end

# TODO: submit PRs to wix/cygwin cookbooks -- for now, inline the few lines we need

# first download base system, because installer fails to download in unattended mode
windows_zipfile "cygwin-base" do
  path      Chef::Config[:file_cache_path]
  source    node['cygwin']['base']['url']
  checksum  node['cygwin']['base']['checksum']
  overwrite true

  action :unzip
end

# the above unzips to this directory
cygPackages = File.join(Chef::Config[:file_cache_path], "cygwin")

remote_file "#{Chef::Config[:file_cache_path]}/cygwin-setup.exe" do
  source node['cygwin']['installer']['url']
  action :create_if_missing
end

execute "cygwin-setup" do
  cwd     Chef::Config[:file_cache_path]
  command "cygwin-setup.exe -q -L -l #{cygPackages} -O -R #{node['cygwin']['home']}"
end

windows_zipfile "wix" do
  path      node['wix']['home']
  source    node['wix']['url']
  checksum  node['wix']['checksum']
  overwrite true

  action :unzip
end

windows_path "#{node['cygwin']['home']}\\bin" do
  action :add
end

# update path
windows_path node['wix']['home'] do
 action :add
end

# git_user 'jenkins' do
#   full_name   'Scala Jenkins'
#   email       'adriaan@typesafe.com'
# end
