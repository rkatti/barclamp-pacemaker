#
# Cookbook Name:: crowbar-pacemaker
# Recipe:: haproxy
#
# Copyright 2014, SUSE
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


#FIXME: delete group when it's not needed anymore 
#FIXME: need to find/write OCF for haproxy  

# Always do the setup for haproxy, so that the RA will already be available on
# all nodes when needed (this avoids the need for "crm resource refresh")
include_recipe "haproxy::setup"

if node[:pacemaker][:haproxy][:enabled]
  service "haproxy" do
    supports :restart => true, :status => true, :reload => true
    action :nothing
    subscribes :reload, "template[#{node[:haproxy][:platform][:config_file]}]", :immediately
  end

  vip_primitives = []
  service_name = "haproxy-service"

  node[:pacemaker][:haproxy][:networks].each do |network, enabled|
    vip_primitive = pacemaker_vip_primitive "HAProxy VIP for #{network}" do
      cb_network network
      # See allocate_cluster_virtual_ips_for_networks in barclamp-crowbar
      hostname CrowbarPacemakerHelper.cluster_vhostname(node)
      domain node[:domain]
      op node[:pacemaker][:haproxy][:op]
    end
    vip_primitives << vip_primitive
  end

  # Allow one retry, to avoid races where two nodes create the primitive at the
  # same time when it wasn't created yet (only one can obviously succeed)
  pacemaker_primitive service_name do
    agent node[:pacemaker][:haproxy][:agent]
    op node[:pacemaker][:haproxy][:op]
    action :create
    retries 1
    retry_delay 5
  end

  # Allow one retry, to avoid races where two nodes create the primitive at the
  # same time when it wasn't created yet (only one can obviously succeed)
  pacemaker_group "haproxy-group" do
    # Membership order *is* significant; VIPs should come first so
    # that they are available for the haproxy service to bind to.
    members vip_primitives + [service_name]
    meta ({
      "is-managed" => true,
      "target-role" => "started"
    })
    action [ :create, :start ]
    retries 1
    retry_delay 5
  end
end
