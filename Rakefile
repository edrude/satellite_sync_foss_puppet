# frozen_string_literal: true

require 'rubocop/rake_task'
require 'rspec/core/rake_task'

RuboCop::RakeTask.new
RSpec::Core::RakeTask.new(:rspec) do |t|
  t.rspec_opts = '--format documentation'
end

task default: %i[rubocop rspec]
