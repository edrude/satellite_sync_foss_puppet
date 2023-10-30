# frozen_string_literal: true

require 'erb'

require_relative '../lib/satellite_hammer_interface'

# Used to keep Satellite 6 Puppet environments in sync with a desired list of environments
class PuppetEnvironmentSyncer
  def initialize(location_id: nil, organization_id: nil, protected_environments: ['production'],
                 never_add_environments: ['gh-pages'], verbose: false)
    @shi = SatelliteHammerInterface.new
    @location_id = location_id
    @organization_id = organization_id
    @verbose = verbose
    @protected_environments = protected_environments
    @never_add_environments = never_add_environments
    @encoded_eol = ERB::Util.url_encode("\n")
  end

  def output_verbose(message)
    puts message if @verbose
  end

  def sync_puppet_environments(desired_environments)
    current_environments = @shi.puppetenvironment_list(location_id: @location_id, organization_id: @organization_id)
    to_add = (desired_environments - current_environments - @never_add_environments)
    to_remove = (current_environments - desired_environments)

    protect_puppet_environments(to_remove)
    add_puppet_environments(to_add) unless to_add.empty?
    delete_puppet_environments(to_remove) unless to_remove.empty?
  end

  def protect_puppet_environments(to_remove)
    return unless to_remove.any? { |env| @protected_environments.include?(env) }

    warn '::warning::Since we tried to delete a protected environment ' \
         "(#{@protected_environments.join(', ')})" \
         ', a human should examine the situation.'
    raise 'Cannot delete protected environment(s)'
  end

  def add_puppet_environments(environments)
    environments.each do |env|
      output_verbose "Creating #{env} environment"
      @shi.puppetenvironment_create(env, location_id: @location_id, organization_id: @organization_id)
    end
  end

  def delete_puppet_environments(environments)
    refused_to_delete = {}
    environments.each do |env|
      hosts = @shi.host_list(search: "environment = #{env}", location_id: @location_id,
                             organization_id: @organization_id)
      refused_to_delete[env] = hosts and next unless hosts.empty?

      output_verbose "Deleting #{env} environment"
      @shi.puppetenvironment_delete(env)
    end

    handle_delete_refusals(refused_to_delete) unless refused_to_delete.empty?
  end

  def handle_delete_refusals(delete_refusals)
    delete_refusals.each do |env, hosts|
      warn '::warning title=Attempted to Delete Environment with Hosts::Refused to delete ' \
           "#{env} environment because it is still used by these hosts:#{@encoded_eol}#{hosts.join(@encoded_eol)}"
    end
  end

  def force_delete_puppet_environment(delete_environment, replace_environment)
    hosts = @shi.host_list(search: "environment = #{delete_environment}", location_id: @location_id,
                           organization_id: @organization_id)
    hosts.each do |host|
      output_verbose "Updating #{host} to use #{replace_environment} environment instead of #{delete_environment}"
      @shi.host_update_puppetenvironment(host, replace_environment)
    end
    output_verbose "Deleting #{delete_environment} environment"
    @shi.puppetenvironment_delete(delete_environment)
  end
end
