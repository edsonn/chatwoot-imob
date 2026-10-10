require 'rails_helper'

RSpec.describe Crm::MoveDealService do
  let(:account) { create(:account) }
  let(:pipeline) { create(:crm_pipeline, account: account) }
  let(:stage_open_1) { create(:crm_pipeline_stage, account: account, pipeline: pipeline, position: 0, stage_type: :open) }
  let(:stage_open_2) { create(:crm_pipeline_stage, account: account, pipeline: pipeline, position: 1, stage_type: :open) }
  let(:stage_won) { create(:crm_pipeline_stage, :won, account: account, pipeline: pipeline, position: 2) }
  let(:stage_lost) { create(:crm_pipeline_stage, :lost, account: account, pipeline: pipeline, position: 3) }

  let(:deal) { create(:crm_deal, account: account, stage: stage_open_1, position: 0, status: :open) }
  let(:user) { create(:user) }

  before do
    create(:account_user, account: account, user: user)
  end

  describe '#perform' do
    context 'when moving between open stages' do
      it 'updates stage, position, last_activity_at and creates a DealActivity' do
        service = described_class.new(deal: deal, target_stage: stage_open_2, user: user, position: 5)
        updated_deal = service.perform

        expect(updated_deal.stage).to eq(stage_open_2)
        expect(updated_deal.position).to eq(5)
        expect(updated_deal.status).to eq('open')
        expect(updated_deal.closed_at).to be_nil
        expect(updated_deal.last_activity_at).to be_present

        activity = deal.activities.last
        expect(activity).to be_present
        expect(activity.activity_type).to eq('stage_change')
        expect(activity.from_stage).to eq(stage_open_1)
        expect(activity.to_stage).to eq(stage_open_2)
        expect(activity.user).to eq(user)
        expect(activity.metadata).to eq({ 'from_position' => 0, 'to_position' => 5 })
      end
    end

    context 'when moving to won stage' do
      it 'sets status to won and closed_at timestamp' do
        service = described_class.new(deal: deal, target_stage: stage_won, user: user)
        updated_deal = service.perform

        expect(updated_deal.stage).to eq(stage_won)
        expect(updated_deal.status).to eq('won')
        expect(updated_deal.closed_at).to be_present
      end
    end

    context 'when moving to lost stage' do
      it 'sets status to lost and closed_at timestamp without requiring loss_reason in Phase 1' do
        service = described_class.new(deal: deal, target_stage: stage_lost, user: user)
        updated_deal = service.perform

        expect(updated_deal.stage).to eq(stage_lost)
        expect(updated_deal.status).to eq('lost')
        expect(updated_deal.closed_at).to be_present
        expect(updated_deal.loss_reason).to be_nil
      end
    end

    context 'when reopening a closed deal to an open stage' do
      let(:closed_deal) { create(:crm_deal, :won, account: account, stage: stage_won) }

      it 'resets status to open and clears closed_at' do
        service = described_class.new(deal: closed_deal, target_stage: stage_open_1, user: user)
        updated_deal = service.perform

        expect(updated_deal.stage).to eq(stage_open_1)
        expect(updated_deal.status).to eq('open')
        expect(updated_deal.closed_at).to be_nil
      end
    end

    context 'when target stage belongs to a different pipeline' do
      let(:other_pipeline) { create(:crm_pipeline, account: account) }
      let(:other_pipeline_stage) { create(:crm_pipeline_stage, account: account, pipeline: other_pipeline) }

      it 'raises MoveError and does not update deal' do
        service = described_class.new(deal: deal, target_stage: other_pipeline_stage, user: user)

        expect { service.perform }.to raise_error(
          Crm::MoveDealService::MoveError,
          'Target stage must belong to the same pipeline'
        )
        expect(deal.reload.stage).to eq(stage_open_1)
      end
    end

    context 'when target stage belongs to a different account' do
      let(:other_account) { create(:account) }
      let(:other_account_stage) { create(:crm_pipeline_stage, account: other_account) }

      it 'raises MoveError and does not update deal' do
        service = described_class.new(deal: deal, target_stage: other_account_stage, user: user)

        expect { service.perform }.to raise_error(
          Crm::MoveDealService::MoveError,
          'Deal and target stage must belong to the same account'
        )
        expect(deal.reload.stage).to eq(stage_open_1)
      end
    end

    context 'when transaction fails during activity creation' do
      it 'rolls back deal changes' do
        service = described_class.new(deal: deal, target_stage: stage_open_2, user: user)

        allow(deal.activities).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Crm::DealActivity.new))

        expect do
          service.perform
        rescue StandardError
          nil
        end.not_to(change { deal.reload.crm_pipeline_stage_id })

        expect(deal.reload.stage).to eq(stage_open_1)
      end
    end
  end
end
