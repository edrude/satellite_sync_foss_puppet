# frozen_string_literal: true

require 'spec_helper'
require_relative '../utils/puppet_environment_syncer'

RSpec.describe PuppetEnvironmentSyncer do
  let(:syncer) { described_class.new }
  let(:shi) { instance_double('SatelliteHammerInterface') }

  before do
    allow(SatelliteHammerInterface).to receive(:new).and_return(shi)
  end

  context 'when init without any arguments' do
    describe '#sync_puppet_environments' do
      before do
        allow(shi).to receive(:puppetenvironment_list).and_return(current_environments)
        allow(syncer).to receive(:add_puppet_environments)
        allow(syncer).to receive(:delete_puppet_environments)
      end

      context 'when desired and current environments are just production' do
        let(:desired_environments) { ['production'] }
        let(:current_environments) { ['production'] }

        it 'does not call add_puppet_environments' do
          expect(syncer).not_to receive(:add_puppet_environments)
          syncer.sync_puppet_environments(desired_environments)
        end

        it 'does not call delete_puppet_environments' do
          expect(syncer).not_to receive(:delete_puppet_environments)
          syncer.sync_puppet_environments(desired_environments)
        end
      end

      context 'when desired is a superset of current environments' do
        let(:desired_environments) { %w[production development] }
        let(:current_environments) { ['production'] }

        it 'calls add_puppet_environments' do
          expect(syncer).to receive(:add_puppet_environments)
          syncer.sync_puppet_environments(desired_environments)
        end

        it 'does not call delete_puppet_environments' do
          expect(syncer).not_to receive(:delete_puppet_environments)
          syncer.sync_puppet_environments(desired_environments)
        end
      end

      context 'when desired is a subset of current environments' do
        let(:desired_environments) { ['production'] }
        let(:current_environments) { %w[production development] }

        it 'calls delete_puppet_environments' do
          expect(syncer).to receive(:delete_puppet_environments)
          syncer.sync_puppet_environments(desired_environments)
        end

        it 'does not call add_puppet_environments' do
          expect(syncer).not_to receive(:add_puppet_environments)
          syncer.sync_puppet_environments(desired_environments)
        end
        context 'when logic indicates production should be deleted' do
          let(:desired_environments) { ['development'] }

          it 'does not call delete_puppet_environments' do
            sync = -> { syncer.sync_puppet_environments(desired_environments) }
            expect(syncer).not_to receive(:delete_puppet_environments)
            expect(&sync).to raise_error(/Cannot delete protected environment/)
              .and output(/Since we tried to delete a protected environment/).to_stderr
          end
        end
      end
    end

    describe '#delete_puppet_environments' do
      before do
        allow(shi).to receive(:puppetenvironment_delete).with('development').and_return(true)
      end

      context 'when environments dont have any hosts' do
        before do
          allow(shi).to receive(:host_list).with(search: 'environment = development',
                                                 location_id: nil, organization_id: nil).and_return([])
        end

        let(:environments) { ['development'] }

        it 'deletes the environment' do
          expect(shi).to receive(:puppetenvironment_delete).with('development')
          syncer.delete_puppet_environments(environments)
        end
      end

      context 'when environments have hosts' do
        before do
          allow(shi).to receive(:host_list).with(search: 'environment = development',
                                                 location_id: nil, organization_id: nil).and_return(['host'])
        end

        let(:environments) { ['development'] }

        it 'does not delete the environment' do
          delete = -> { syncer.delete_puppet_environments(environments) }
          expect(shi).not_to receive(:puppetenvironment_delete).with('development')
          expect(&delete).to output(/Refused to delete development environment/).to_stderr
        end
      end
    end

    describe '#force_delete_puppet_environment' do
      context 'when environment has hosts' do
        before do
          allow(shi).to receive(:puppetenvironment_delete).with('development').and_return(true)
          allow(shi).to receive(:host_update_puppetenvironment).with('host', 'production').and_return(true)
          allow(shi).to receive(:host_list).with(search: 'environment = development',
                                                 location_id: nil, organization_id: nil).and_return(['host'])
        end

        let(:delete_environment) { 'development' }
        let(:replace_environment) { 'production' }

        it 'moves hosts out of the environment' do
          expect(shi).to receive(:host_update_puppetenvironment).with('host', 'production')
          syncer.force_delete_puppet_environment(delete_environment, replace_environment)
        end

        it 'deletes the environment' do
          expect(shi).to receive(:puppetenvironment_delete).with('development')
          syncer.force_delete_puppet_environment(delete_environment, replace_environment)
        end
      end
    end
  end
end
