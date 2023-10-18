#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'yaml'
require 'optparse'

# Default values
options = {
  org_id: 5,
  loc_id: 6
}

# Hammer command base
hammer_base = '/usr/bin/hammer'

# Parsing command-line options
OptionParser.new do |opts|
  opts.banner = 'Usage: sync_environments.rb [options]'

  opts.on('-f', '--file [FILE]', 'Path to a YAML file containing the desired environments') do |file|
    options[:file] = file
  end

  opts.on('-e', '--environments x,y,z', Array, 'List of environments, separated by commas') do |list|
    options[:environments] = list
  end
end.parse!

# Function to validate the inputs provided by the user
def validate_options(options)
  if options[:file].nil? && options[:environments].nil?
    raise 'Please provide a YAML file or a list of environments.'
  elsif options[:file] && options[:environments]
    raise 'Please provide either a YAML file or a list of environments, not both.'
  end
end

# Validate the provided inputs
validate_options(options)

# Read environments from a YAML file or use the provided list
if options[:file]
  filepath = options[:file]
  raise "The file #{filepath} does not exist." unless File.exist?(filepath)

  desired_environments = YAML.load_file(filepath) # Assumes the file contains a valid array of strings.
elsif options[:environments]
  desired_environments = options[:environments]
else
  raise 'No environments specified.'
end

# Fetch the list of current environments in YAML format
command = [
  hammer_base,
  '--output yaml',
  'puppet-environment list',
  "--organization-id #{options[:org_id]}",
  "--location-id #{options[:loc_id]}"
].join(' ')
stdout, stderr, status = Open3.capture3(command)

raise "Error fetching environments: #{stderr}" unless status.success?

# Load the output as YAML
current_environments_data = YAML.safe_load(stdout)
current_environments = current_environments_data.map { |env| env['Name'] }

# Output the current environments
puts 'Current environments:'
puts "#{current_environments.join("\n")}\n\n"

# Output the desired environments
puts 'Desired environments:'
puts "#{desired_environments.join("\n")}\n\n"

# Never add or remove 'production'
if desired_environments.include?('production') && !current_environments.include?('production')
  puts "Warning: 'production' environment is protected and cannot be added automatically.\n"
  desired_environments.delete('production')
end

# Create environments that are missing
desired_environments.each do |environment|
  next if current_environments.include?(environment)

  puts "Adding environment: #{environment}"
  create_command = [
    hammer_base,
    'puppet-environment create',
    "--name #{environment}",
    "--organization-ids #{options[:org_id]}",
    "--location-ids #{options[:loc_id]}"
  ].join(' ')
  _, stderr, status = Open3.capture3(create_command)

  raise "Error creating environment #{environment}: #{stderr}" unless status.success?
end

# Delete the ones that are not in the desired list, except 'production'
environments_to_delete = current_environments - desired_environments
environments_to_delete.each do |environment|
  if environment == 'production'
    puts "\nWarning: 'production' environment is protected and will not be removed."
  else
    puts "Removing environment: #{environment}"
    _, stderr, status = Open3.capture3("#{hammer_base} puppet-environment delete --name #{environment}")
    raise "Error deleting environment #{environment}: #{stderr}" unless status.success?
  end
end

puts "\nSynchronization complete."
