# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Crm::LostDealService do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }

  let(:pipeline) { create(:crm_pipeline, account: account) }
  let(:other_pipeline) { create(:crm_pipeline, account: account) }

  let(:stage_open) { create(:crm_pipeline_stage, account: account, pipeline: pipeline, stage_type: :open) }
  let(:stage_lost) { create(:crm_pipeline_stage, :lost, account: account, pipeline: pipeline) }
  let(:other_pipeline_lost_stage) { create(:crm_pipeline_stage, :lost, account: account, pipeline: other_pipeline) }
  let(:other_stage) { create(:crm_pipeline_stage, account: other_account) }

  let(:loss_reason) { create(:crm_loss_reason, account: account, name: 'Preço alto') }
  let(:other_loss_reason) { create(:crm_loss_reason, account: other_account) }

  let(:deal) { create(:crm_deal, account: account, stage: stage_open, status: :open) }
  let(:user) { create(:user) }

  before do
    create(:account_user, account: account, user: user)
    stage_lost
  end

  describe '#perform' do
    it 'marks deal as lost with loss_reason, notes, closed_at and creates a status_change activity' do
      service = described_class.new(
        deal: deal,
        user: user,
        params: {
          crm_loss_reason_id: loss_reason.id,
          loss_notes: 'Cliente achou o valor acima do planejado',
          crm_pipeline_stage_id: stage_lost.id
        }
      )
      lost_deal = service.perform

      expect(lost_deal.status).to eq('lost')
      expect(lost_deal.loss_reason).to eq(loss_reason)
      expect(lost_deal.loss_notes).to eq('Cliente achou o valor acima do planejado')
      expect(lost_deal.closed_at).to be_present
      expect(lost_deal.stage).to eq(stage_lost)
      expect(lost_deal.last_activity_at).to be_present

      activity = deal.activities.last
      expect(activity).to be_present
      expect(activity.activity_type).to eq('status_change')
      expect(activity.notes).to eq('Cliente achou o valor acima do planejado')
      expect(activity.metadata['new_status']).to eq('lost')
      expect(activity.metadata['loss_reason_id']).to eq(loss_reason.id)
    end

    it 'finds lost stage automatically when crm_pipeline_stage_id is omitted' do
      service = described_class.new(
        deal: deal,
        user: user,
        params: { crm_loss_reason_id: loss_reason.id }
      )
      lost_deal = service.perform

      expect(lost_deal.status).to eq('lost')
      expect(lost_deal.stage).to eq(stage_lost)
    end

    it 'raises LostError if crm_loss_reason_id is missing' do
      service = described_class.new(deal: deal, user: user, params: {})
      expect { service.perform }.to raise_error(described_class::LostError, /Loss reason is required/)
    end

    it 'raises LostError if loss reason belongs to another account' do
      service = described_class.new(deal: deal, user: user, params: { crm_loss_reason_id: other_loss_reason.id })
      expect { service.perform }.to raise_error(described_class::LostError, /Invalid loss reason/)
    end

    it 'raises LostError if target stage belongs to another account' do
      service = described_class.new(
        deal: deal,
        user: user,
        params: { crm_loss_reason_id: loss_reason.id, crm_pipeline_stage_id: other_stage.id }
      )
      expect { service.perform }.to raise_error(described_class::LostError, /same account/)
    end

    it 'raises LostError if target stage belongs to another pipeline of the same account' do
      service = described_class.new(
        deal: deal,
        user: user,
        params: { crm_loss_reason_id: loss_reason.id, crm_pipeline_stage_id: other_pipeline_lost_stage.id }
      )
      expect { service.perform }.to raise_error(described_class::LostError, /same pipeline/)
    end

    it 'raises LostError if target stage does not have stage_type lost' do
      service = described_class.new(
        deal: deal,
        user: user,
        params: { crm_loss_reason_id: loss_reason.id, crm_pipeline_stage_id: stage_open.id }
      )
      expect { service.perform }.to raise_error(described_class::LostError, /stage_type lost/)
    end

    it 'raises LostError when no lost stage exists in the current pipeline and none is passed' do
      pipeline_without_lost = create(:crm_pipeline, account: account)
      stage_only_open = create(:crm_pipeline_stage, account: account, pipeline: pipeline_without_lost, stage_type: :open)
      deal_without_lost_stage = create(:crm_deal, account: account, stage: stage_only_open, status: :open)

      service = described_class.new(
        deal: deal_without_lost_stage,
        user: user,
        params: { crm_loss_reason_id: loss_reason.id }
      )
      expect { service.perform }.to raise_error(described_class::LostError, /Lost stage not found in pipeline/)
    end

    it 'ensures deal and activities remain unchanged on validation failure' do
      initial_activities_count = deal.activities.count
      service = described_class.new(
        deal: deal,
        user: user,
        params: { crm_loss_reason_id: loss_reason.id, crm_pipeline_stage_id: other_pipeline_lost_stage.id }
      )

      expect { service.perform }.to raise_error(described_class::LostError)
      deal.reload
      expect(deal.status).to eq('open')
      expect(deal.stage).to eq(stage_open)
      expect(deal.activities.count).to eq(initial_activities_count)
    end
  end
end
