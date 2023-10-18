#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'yaml'
require 'optparse'

# This script will synchronize the Puppet environments in Satellite with the environments specified in a YAML file.
class PuppetEnvironmentSyncer
  attr_reader :options, :current_environments, :desired_environments

  def initialize
    @options = {
      org_id: 5,
      loc_id: 6
    }
    @hammer_base = '/usr/bin/hammer'
    parse_cli_options!
    validate_options
  end

  def parse_cli_options!
    OptionParser.new do |opts|
      opts.banner = 'Usage: sync_puppet_environments.rb [options]'

      opts.on('-f', '--file [FILE]', 'Path to a YAML file containing the desired environments') do |file|
        @options[:file] = file
      end

      opts.on('-e', '--environments x,y,z', Array, 'List of environments, separated by commas') do |list|
        @options[:environments] = list
      end
    end.parse!
  end

  def validate_options
    if @options[:file].nil? && @options[:environments].nil?
      raise 'Please provide a YAML file or a list of environments.'
    elsif @options[:file] && @options[:environments]
      raise 'Please provide either a YAML file or a list of environments, not both.'
    end
  end

  def load_desired_environments
    if @options[:file]
      filepath = @options[:file]
      raise "The file #{filepath} does not exist." unless File.exist?(filepath)

      @desired_environments = YAML.load_file(filepath)
    elsif @options[:environments]
      @desired_environments = @options[:environments]
    else
      raise 'No environments specified.'
    end
  end

  def fetch_current_environments
    command = [
      @hammer_base,
      '--output yaml',
      'puppet-environment list',
      "--organization-id #{@options[:org_id]} --location-id #{@options[:loc_id]}"
    ].join(' ')
    stdout, stderr, status = Open3.capture3(command)

    raise "Error fetching environments: #{stderr}" unless status.success?

    current_environments_data = YAML.safe_load(stdout)
    @current_environments = current_environments_data.map { |env| env['Name'] }
  end

  def sync_environments
    @desired_environments.each do |environment|
      add_environment(environment) unless @current_environments.include?(environment)
    end

    (@current_environments - @desired_environments).each do |environment|
      if environment == 'production'
        puts "Warning: 'production' environment is protected and cannot be removed automatically.\n"
        next
      end
      remove_environment(environment)
    end
  end

  def add_environment(environment)
    puts "Adding environment: #{environment}"
    create_command = [
      @hammer_base,
      'puppet-environment create',
      "--name #{environment}",
      "--organization-ids #{@options[:org_id]} --location-ids #{@options[:loc_id]}"
    ].join(' ')
    _, stderr, status = Open3.capture3(create_command)

    raise "Error creating environment #{environment}: #{stderr}" unless status.success?
  end

  def remove_environment(environment)
    puts "Removing environment: #{environment}"
    _, stderr, status = Open3.capture3("#{@hammer_base} puppet-environment delete --name #{environment}")
    raise "Error deleting environment #{environment}: #{stderr}" unless status.success?
  end

  def run
    load_desired_environments
    fetch_current_environments
    sync_environments
    puts "\nSynchronization complete."
  end
end

if __FILE__ == $PROGRAM_NAME
  syncer = PuppetEnvironmentSyncer.new
  syncer.run
end
