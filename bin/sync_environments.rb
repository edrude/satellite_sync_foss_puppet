#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

require_relative '../utils/puppet_environment_syncer'

options = {
  org_id: 5,
  loc_id: 6
}
OptionParser.new do |opts|
  opts.banner = 'Usage: sync_puppet_environments.rb [options]'
  opts.on('-e', '--environments x,y,z', Array, 'List of environments, separated by commas') do |list|
    options[:environments] = list
  end
end.parse!

raise 'Please provide a list of environments.' if options[:environments].nil?

syncer = PuppetEnvironmentSyncer.new(organization_id: options[:org_id], location_id: options[:loc_id], verbose: true)

syncer.sync_puppet_environments(options[:environments])
