# frozen_string_literal: true

require 'spec_helper'
require_relative '../sync_puppet_environments'

describe PuppetEnvironmentSyncer do
  let(:syncer) { described_class.new }
  let(:environments_yaml) { File.join('spec', 'fixtures', 'environments.yml') }
  let(:hammer_fetch_yaml) do
    <<~YAML
      ---
      - Id: 1
        Name: production
      - Id: 16
        Name: testing
    YAML
  end

  # Mocking the external dependencies, the file system operation, and the system call
  before do
    allow(Open3).to receive(:capture3)
    stub_const('ARGV', ['-e', 'production'])
  end

  describe 'initialize' do
    it 'initializes with default options' do
      expect(syncer.options).to eq({ environments: ['production'], loc_id: 6, org_id: 5 })
    end
  end

  describe 'load_desired_environments' do
    context 'when file option is provided' do
      it 'loads environments from a YAML file' do
        syncer.options[:file] = environments_yaml
        syncer.load_desired_environments

        expect(syncer.desired_environments).to contain_exactly('development', 'production')
      end
    end

    context 'when environments option is provided' do
      before { stub_const('ARGV', ['-e', 'production,development']) }

      it 'loads environments from the provided list' do
        syncer.load_desired_environments

        expect(syncer.desired_environments).to contain_exactly('development', 'production')
      end
    end
  end

  describe 'fetch_current_environments' do
    it 'fetches the current environments' do
      # allow(YAML).to receive(:safe_load).and_return([{ 'Name' => 'production' }, { 'Name' => 'development' }])
      allow(Open3).to receive(:capture3).and_return([hammer_fetch_yaml, nil,
                                                     instance_double(Process::Status, success?: true)])

      syncer.fetch_current_environments

      expect(syncer.current_environments).to contain_exactly('production', 'testing')
    end
  end

  describe 'sync_environments' do
    before do
      allow(syncer).to receive(:add_environment).and_return(nil)
      allow(syncer).to receive(:remove_environment).and_return(nil)
    end

    context 'when the desired state is the same as the current' do
      before do
        syncer.instance_variable_set(:@current_environments, ['production'])
        syncer.instance_variable_set(:@desired_environments, ['production'])
      end

      it 'does not call add_environment or remove_environment' do
        expect(syncer).not_to receive(:add_environment)
        expect(syncer).not_to receive(:remove_environment)
        syncer.sync_environments
      end
    end

    context 'when there are only environments to add' do
      before do
        syncer.instance_variable_set(:@current_environments, ['production'])
        syncer.instance_variable_set(:@desired_environments, %w[production development])
      end

      it 'calls the add_environment method for environments not present' do
        expect(syncer).to receive(:add_environment).with('development')
        syncer.sync_environments
      end

      it 'does not call the remove_environment method' do
        expect(syncer).not_to receive(:remove_environment)
        syncer.sync_environments
      end
    end

    context 'when there are only environments to remove' do
      before do
        syncer.instance_variable_set(:@current_environments, %w[production development])
        syncer.instance_variable_set(:@desired_environments, ['production'])
      end

      it 'calls the remove_environment method for environments not present' do
        expect(syncer).to receive(:remove_environment).with('development')
        syncer.sync_environments
      end

      it 'does not call the add_environment method' do
        expect(syncer).not_to receive(:add_environment)
        syncer.sync_environments
      end
    end
    context 'when input is indicating to remove the production environment' do
      before do
        syncer.instance_variable_set(:@current_environments, %w[production development])
        syncer.instance_variable_set(:@desired_environments, ['development'])
      end

      it 'does not call the remove_environment method and prints a warning' do
        expect(syncer).not_to receive(:remove_environment)
        expect { syncer.sync_environments }.to output(/Warning:/).to_stdout
      end
    end
  end
end
