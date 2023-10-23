# frozen_string_literal: true

require 'open3'

# This class is used to interface with the satellite_hammer binary
class SatelliteHammerInterface
  def initialize(hammer_path = nil)
    hammer_path ||= '/usr/bin/hammer'
    @hammer_command = "#{hammer_path} --output yaml"
  end

  def run_satellite_hammer(args)
    stdout, stderr, status = Open3.capture3(@hammer_command, *args)
    [stdout, stderr, status]
  end

  def puppetenvironment_create(name, location_id = nil, organization_id = nil)
    args = ['puppet-environment', 'create', '--name', name]
    args << '--location-id' << location_id if location_id
    args << '--organization-id' << organization_id if organization_id
    _, stderr, status = run_satellite_hammer(args)
    raise "Failed to delete puppet environment\n#{stderr}" unless status.success?
  end

  def puppetenvironment_delete(name)
    args = ['puppet-environment', 'delete', '--name', name]
    _, stderr, status = run_satellite_hammer(args)
    raise "Failed to delete puppet environment\n#{stderr}" unless status.success?
  end

  def puppetenvironment_list(location_id = nil, organization_id = nil)
    args = %w[puppet-environment list]
    args << '--location-id' << location_id if location_id
    args << '--organization-id' << organization_id if organization_id
    stdout, stderr, status = run_satellite_hammer(args)
    raise "Failed to delete puppet environment\n#{stderr}" unless status.success?

    current_environments_data = YAML.safe_load(stdout)
    current_environments_data.map { |env| env['Name'] }
  end

  def host_update_puppetenvironment(host, puppet_environment)
    args = ['host update', '--name', host, '--puppet-environment', puppet_environment]
    _, stderr, status = run_satellite_hammer(args)
    raise "Failed to update puppet environment\n#{stderr}" unless status.success?
  end

  def host_list(search = nil, location_id = nil, organization_id = nil)
    args = %w[host list]
    args << '--search' << search if search
    args << '--location-id' << location_id if location_id
    args << '--organization-id' << organization_id if organization_id
    stdout, stderr, status = run_satellite_hammer(args)
    raise "Failed to list hosts\n#{stderr}" unless status.success?

    current_hosts_data = YAML.safe_load(stdout)
    current_hosts_data.map { |host| host['Name'] }
  end
end
