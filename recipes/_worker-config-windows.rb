#
# Cookbook Name:: scala-jenkins-infra
# Recipe:: _worker-config-windows
#
# Copyright 2014, Typesafe, Inc.
#
# All rights reserved - Do Not Redistribute
#


node["jenkinsHomes"].each do |jenkinsHome, workerConfig|
  if workerConfig["publish"]
    s3Downloads = chef_vault_item("worker-publish", "s3-downloads")

    # TODO: once s3-plugin supports it, use instance profile instead of credentials
    {
      "#{jenkinsHome}/.s3credentials" => "s3credentials.erb"
    }.each do |target, templ|
      template target do
        source    templ
        sensitive true
        user      workerConfig["jenkinsUser"]

        variables({
          :s3Downloads => s3Downloads
        })
      end
    end

    # (only) needed for WIX ICE validation (http://windows-installer-xml-wix-toolset.687559.n2.nabble.com/Wix-3-5-amp-Cruise-Control-gives-errorLGHT0217-td6039205.html#a6039814)
    # wix was failing, added jenkins to this group, rebooted (required!), then it worked
    group "Administrators" do
      action :modify
      members workerConfig["jenkinsUser"]
      append true
    end
  end
end

# TODO upgrade to https://wix.codeplex.com/releases/view/619491
# windows_package 'WIX' do
#   source node['wix']['url']
#   action :install
# end


include_recipe 'scala-jenkins-infra::_worker-config-windows-cygwin'
