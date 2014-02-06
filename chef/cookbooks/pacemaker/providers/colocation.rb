# Author:: Robert Choi
# Cookbook Name:: pacemaker
# Provider:: colocation
#
# Copyright:: 2013, Robert Choi
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

require ::File.expand_path('../libraries/pacemaker', ::File.dirname(__FILE__))
require ::File.expand_path('../libraries/chef/mixin/pacemaker',
                           ::File.dirname(__FILE__))

include Chef::Mixin::Pacemaker::StandardCIBObject

action :create do
  name = new_resource.name

  if @current_resource_definition.nil?
    create_resource(name)
  else
    maybe_modify_resource(name)
  end
end

action :delete do
  name = new_resource.name
  next unless @current_resource
  rsc = cib_object_class.new(name)
  execute rsc.delete_command do
    action :nothing
  end.run_action(:run)
  new_resource.updated_by_last_action(true)
  Chef::Log.info "Deleted #{@current_cib_object}'."
end

def cib_object_class
  ::Pacemaker::Constraint::Colocation
end

def load_current_resource
  standard_load_current_resource
end

def init_current_resource
  name = @new_resource.name
  @current_resource = Chef::Resource::PacemakerColocation.new(name)
  attrs = [:score, :resources]
  @current_cib_object.copy_attrs_to_chef_resource(@current_resource, *attrs)
end

def create_resource(name)
  standard_create_resource
end

def maybe_modify_resource(name)
  Chef::Log.info "Checking existing #{@current_cib_object} for modifications"

  desired_colocation = cib_object_class.from_chef_resource(new_resource)
  if desired_colocation.definition_string != @current_cib_object.definition_string
    Chef::Log.debug "changed from [#{@current_cib_object.definition_string}] to [#{desired_colocation.definition_string}]"
    cmd = desired_colocation.reconfigure_command
    execute cmd do
      action :nothing
    end.run_action(:run)
    new_resource.updated_by_last_action(true)
  end
end
