# Copyright 2011, Dell, Inc.
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

case node.platform
when 'suse'
  default[:pacemaker][:platform][:packages] = %w(pacemaker crmsh)

  # pacemaker-mgmt-client provides hb_gui, which it's useful
  # to run over ssh.  Note that pacemaker-mgmt needs to be installed
  # *before* the openais service is started, otherwise the mgmtd
  # plugin won't be forked as a child process.
  default[:pacemaker][:platform][:graphical_packages] = %w(
    pacemaker-mgmt pacemaker-mgmt-client
    xorg-x11-xauth xorg-x11-fonts
  )
else
  Chef::Application.fatal! "FIXME: #{node.platform} platform not supported yet"
  return
end

default[:pacemaker][:founder] = false
default[:pacemaker][:crm][:initial_config_file] = "/etc/corosync/crm-initial.conf"
default[:pacemaker][:crm][:no_quorum_policy] = "ignore"

# Values can be "disabled", "manual", "clone", "per_node"
default[:pacemaker][:stonith][:mode] = "disabled"

default[:pacemaker][:stonith][:clone][:plugin] = ""
# This can be either a string (containing a list of parameters) or a hash.
# For instance:
#   default[:pacemaker][:stonith][:clone][:params] = 'hostname="foo" password="bar"'
# will give the same result as:
#   default[:pacemaker][:stonith][:clone][:params] = {"hostname" => "foo", "password" => "bar"}
default[:pacemaker][:stonith][:clone][:params] = {}

default[:pacemaker][:stonith][:per_node][:plugin] = ""
# This hash will contain parameters for each node. See documentation for
# default[:pacemaker][:stonith][:clone][:params] about the format.
# For instance:
#  default[:pacemaker][:stonith][:per_node][:nodes][$node][:params] = 'hostname="foo" password="bar"'
default[:pacemaker][:stonith][:per_node][:nodes] = {}
