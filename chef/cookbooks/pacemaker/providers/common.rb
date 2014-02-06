require 'chef/application'
require ::File.expand_path('../libraries/pacemaker', ::File.dirname(__FILE__))

class Chef
  module Mixin::PacemakerCommon
    # Instantiate @current_resource and read details about the existing
    # primitive (if any) via "crm configure show" into it, so that we
    # can compare it against the resource requested by the recipe, and
    # create / delete / modify as necessary.
    #
    # http://docs.opscode.com/lwrp_custom_provider_ruby.html#load-current-resource
    def standard_load_current_resource
      name = @new_resource.name

      cib_object = Pacemaker::CIBObject.from_name(name)
      unless cib_object
        ::Chef::Log.debug "CIB object definition nil or empty"
        return
      end

      unless cib_object.is_a? cib_object_class
        expected_type = cib_object_class.description
        ::Chef::Log.warn "CIB object '#{name}' was a #{cib_object.type} not a #{expected_type}"
        return
      end

      ::Chef::Log.debug "CIB object definition #{cib_object.definition}"
      @current_resource_definition = cib_object.definition
      cib_object.parse_definition

      @current_cib_object = cib_object
      init_current_resource
    end

    def standard_create_resource
      cib_object = cib_object_class.from_chef_resource(new_resource)
      cmd = cib_object.crm_configure_command

      ::Chef::Log.info "Creating new #{cib_object}"

      execute cmd do
        action :nothing
      end.run_action(:run)

      if cib_object.exists?
        new_resource.updated_by_last_action(true)
        ::Chef::Log.info "Successfully configured #{cib_object}"
      else
        ::Chef::Log.error "Failed to configure #{cib_object}"
      end
    end

  end
end
