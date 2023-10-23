#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative '../utils/puppet_environment_syncer'

syncer = PuppetEnvironmentSyncer.new(verbose: true)

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: force_delete_environment.rb [options]'

  opts.on('-e', '--environment ENVIRONMENT', 'Environment to delete') do |e|
    options[:environment] = e
  end

  opts.on('-r', '--replace-environment ENVIRONMENT', 'Environment to move displacted hosts to') do |r|
    options[:replace_environment] = r
  end
end

raise 'Please provide an environment to delete.' if options[:environment].nil?
raise 'Please provide an environment to move displaced hosts to.' if options[:replace_environment].nil?

syncer.force_delete_puppet_environment(options[:environment], options[:replace_environment])
