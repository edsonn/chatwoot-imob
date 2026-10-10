# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Crm::DealPolicy, type: :policy do
  subject(:deal_policy) { described_class }

  let(:account) { create(:account) }
  let(:other_account) { create(:account) }

  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }

  let(:admin_account_user) { account.account_users.find_by(user_id: administrator.id) }
  let(:agent_account_user) { account.account_users.find_by(user_id: agent.id) }

  let(:admin_context) { { user: administrator, account: account, account_user: admin_account_user } }
  let(:agent_context) { { user: agent, account: account, account_user: agent_account_user } }

  let(:pipeline) { create(:crm_pipeline, account: account) }
  let(:stage) { create(:crm_pipeline_stage, account: account, pipeline: pipeline) }

  let(:unassigned_deal) { create(:crm_deal, account: account, stage: stage, assignee: nil) }
  let(:assigned_to_agent_deal) { create(:crm_deal, account: account, stage: stage, assignee: agent) }
  let(:assigned_to_other_deal) { create(:crm_deal, account: account, stage: stage, assignee: other_agent) }
  let(:other_account_deal) { create(:crm_deal, account: other_account) }

  describe 'Scope' do
    before do
      unassigned_deal
      assigned_to_agent_deal
      assigned_to_other_deal
      other_account_deal
    end

    context 'when administrator' do
      it 'resolves all deals within the account and excludes other accounts' do
        resolved = described_class::Scope.new(admin_context, Crm::Deal.all).resolve
        expect(resolved).to include(unassigned_deal, assigned_to_agent_deal, assigned_to_other_deal)
        expect(resolved).not_to include(other_account_deal)
      end
    end

    context 'when agent' do
      it 'resolves only unassigned deals and deals assigned to the agent' do
        resolved = described_class::Scope.new(agent_context, Crm::Deal.all).resolve
        expect(resolved).to include(unassigned_deal, assigned_to_agent_deal)
        expect(resolved).not_to include(assigned_to_other_deal, other_account_deal)
      end
    end
  end

  describe 'permissions' do
    context 'when administrator' do
      it 'permits full access to deals of the account' do
        expect(deal_policy).to permit(admin_context, unassigned_deal)
        expect(deal_policy).to permit(admin_context, assigned_to_agent_deal)
        expect(deal_policy).to permit(admin_context, assigned_to_other_deal)
      end

      it 'permits creating deal assigned to any agent' do
        expect(described_class.new(admin_context, assigned_to_other_deal).create?).to be(true)
      end

      it 'denies access to deals of another account' do
        expect(deal_policy).not_to permit(admin_context, other_account_deal)
      end
    end

    context 'when agent' do
      it 'permits access to deals assigned to themselves' do
        expect(deal_policy).to permit(agent_context, assigned_to_agent_deal)
      end

      it 'permits access to unassigned deals' do
        expect(deal_policy).to permit(agent_context, unassigned_deal)
      end

      it 'permits creating deal assigned to self or without assignee' do
        expect(described_class.new(agent_context, assigned_to_agent_deal).create?).to be(true)
        expect(described_class.new(agent_context, unassigned_deal).create?).to be(true)
      end

      it 'denies creating deal assigned to another agent' do
        expect(described_class.new(agent_context, assigned_to_other_deal).create?).to be(false)
      end

      it 'denies access to deals assigned to another agent' do
        expect(deal_policy).not_to permit(agent_context, assigned_to_other_deal)
      end

      it 'denies access to deals of another account' do
        expect(deal_policy).not_to permit(agent_context, other_account_deal)
      end

      it 'denies destroy permission' do
        expect(described_class.new(agent_context, assigned_to_agent_deal).destroy?).to be(false)
      end
    end
  end
end
