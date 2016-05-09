#
# Author:: Matt Ray (<matt@chef.io>)
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2012-2016 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "ohai/mixin/ec2_metadata"

Ohai.plugin(:Openstack) do
  include Ohai::Mixin::Ec2Metadata

  provides "openstack"
  depends "dmi"

  # do we have the openstack dmi data
  def openstack_dmi?
    # detect a manufacturer of OpenStack Foundation
    if dmi[:system][:all_records][0][:Manufacturer] =~ /OpenStack/
      Ohai::Log.debug("Plugin Openstack: has_openstack_dmi? == true")
      true
    end
  rescue NoMethodError
    Ohai::Log.debug("Plugin Openstack: has_openstack_dmi? == false")
    false
  end

  # check for the ohai hint and log debug messaging
  def openstack_hint?
    if hint?("openstack")
      Ohai::Log.debug("Plugin Openstack: openstack hint present")
      return true
    else
      Ohai::Log.debug("Plugin Openstack: openstack hint not present")
      return false
    end
  end

  # grab metadata and return a mash. if we can't connect return nil
  def openstack_metadata
    metadata = Mash.new
    if can_metadata_connect?("169.254.169.254", 80)
      fetch_metadata.each do |k, v|
        metadata[k] = v
      end
      Ohai::Log.debug("Plugin Openstack: Successfully fetched Openstack metadata from the metadata endpoint")
    else
      Ohai::Log.debug("Plugin Openstack: Timed out connecting to Openstack metadata endpoint. Skipping metadata.")
    end
    metadata
  end

  collect_data do
    # fetch data if we look like openstack
    if openstack_hint? || openstack_dmi?
      openstack Mash.new
      openstack[:provider] = "openstack" # for now this is our only provider
      openstack[:metadata] = openstack_metadata # fetch metadata or set this to nil
    else
      Ohai::Log.debug("Plugin Openstack: Node does not appear to be an Openstack node")
    end
  end
end
