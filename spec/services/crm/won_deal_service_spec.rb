# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Crm::WonDealService do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }

  let(:pipeline) { create(:crm_pipeline, account: account) }
  let(:other_pipeline) { create(:crm_pipeline, account: account) }

  let(:stage_open) { create(:crm_pipeline_stage, account: account, pipeline: pipeline, stage_type: :open) }
  let(:stage_won) { create(:crm_pipeline_stage, :won, account: account, pipeline: pipeline) }
  let(:other_pipeline_won_stage) { create(:crm_pipeline_stage, :won, account: account, pipeline: other_pipeline) }
  let(:other_account_stage) { create(:crm_pipeline_stage, account: other_account) }

  let(:deal) { create(:crm_deal, account: account, stage: stage_open, value: 500_000.0, status: :open) }
  let(:user) { create(:user) }

  before do
    create(:account_user, account: account, user: user)
    stage_won
  end

  describe '#perform' do
    it 'marks deal as won with final_value, closed_at and creates a status_change activity' do
      service = described_class.new(
        deal: deal,
        user: user,
        params: { final_value: 480_000.0, closed_at: '2026-10-10T12:00:00Z', crm_pipeline_stage_id: stage_won.id }
      )
      won_deal = service.perform

      expect(won_deal.status).to eq('won')
      expect(won_deal.final_value).to eq(480_000.0)
      expect(won_deal.closed_at).to be_present
      expect(won_deal.stage).to eq(stage_won)
      expect(won_deal.last_activity_at).to be_present

      activity = deal.activities.last
      expect(activity).to be_present
      expect(activity.activity_type).to eq('status_change')
      expect(activity.metadata['new_status']).to eq('won')
      expect(activity.metadata['final_value']).to eq('480000.0')
    end

    it 'defaults final_value to deal value and closed_at to Time.current if not provided' do
      service = described_class.new(deal: deal, user: user)
      won_deal = service.perform

      expect(won_deal.status).to eq('won')
      expect(won_deal.final_value).to eq(500_000.0)
      expect(won_deal.closed_at).to be_present
      expect(won_deal.stage).to eq(stage_won)
    end

    it 'raises WonError if target stage belongs to a different account' do
      service = described_class.new(deal: deal, user: user, params: { crm_pipeline_stage_id: other_account_stage.id })
      expect { service.perform }.to raise_error(described_class::WonError, /same account/)
    end

    it 'raises WonError if target stage belongs to another pipeline of the same account' do
      service = described_class.new(deal: deal, user: user, params: { crm_pipeline_stage_id: other_pipeline_won_stage.id })
      expect { service.perform }.to raise_error(described_class::WonError, /same pipeline/)
    end

    it 'raises WonError if target stage does not have stage_type won' do
      service = described_class.new(deal: deal, user: user, params: { crm_pipeline_stage_id: stage_open.id })
      expect { service.perform }.to raise_error(described_class::WonError, /stage_type won/)
    end

    it 'raises WonError when no won stage exists in the current pipeline and none is passed' do
      pipeline_without_won = create(:crm_pipeline, account: account)
      stage_only_open = create(:crm_pipeline_stage, account: account, pipeline: pipeline_without_won, stage_type: :open)
      deal_without_won_stage = create(:crm_deal, account: account, stage: stage_only_open, status: :open)

      service = described_class.new(deal: deal_without_won_stage, user: user)
      expect { service.perform }.to raise_error(described_class::WonError, /Won stage not found in pipeline/)
    end

    it 'ensures deal and activities remain unchanged on validation failure' do
      initial_activities_count = deal.activities.count
      service = described_class.new(deal: deal, user: user, params: { crm_pipeline_stage_id: other_pipeline_won_stage.id })

      expect { service.perform }.to raise_error(described_class::WonError)
      deal.reload
      expect(deal.status).to eq('open')
      expect(deal.stage).to eq(stage_open)
      expect(deal.activities.count).to eq(initial_activities_count)
    end
  end
end
