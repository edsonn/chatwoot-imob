# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Crm::DealTaskPolicy, type: :policy do
  subject(:task_policy) { described_class }

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

  let(:deal_for_agent) { create(:crm_deal, account: account, stage: stage, assignee: agent) }
  let(:deal_for_other) { create(:crm_deal, account: account, stage: stage, assignee: other_agent) }

  let(:task_for_agent) { create(:crm_deal_task, account: account, deal: deal_for_agent, user: agent) }
  let(:task_for_other) { create(:crm_deal_task, account: account, deal: deal_for_other, user: other_agent) }
  let(:other_account_task) { create(:crm_deal_task, account: other_account) }

  describe 'permissions' do
    context 'when administrator' do
      it 'permits access to tasks within the account' do
        expect(task_policy).to permit(admin_context, task_for_agent)
        expect(task_policy).to permit(admin_context, task_for_other)
      end

      it 'permits creating task for any agent in the account' do
        task_new = build(:crm_deal_task, account: account, deal: deal_for_agent, user: other_agent)
        expect(described_class.new(admin_context, task_new).create?).to be(true)
      end

      it 'denies access to tasks of another account' do
        expect(task_policy).not_to permit(admin_context, other_account_task)
      end
    end

    context 'when agent' do
      it 'permits access to task on own deal' do
        expect(task_policy).to permit(agent_context, task_for_agent)
      end

      it 'permits creating task for self on allowed deal' do
        task_new = build(:crm_deal_task, account: account, deal: deal_for_agent, user: agent)
        expect(described_class.new(agent_context, task_new).create?).to be(true)
      end

      it 'denies creating task for another agent' do
        task_new = build(:crm_deal_task, account: account, deal: deal_for_agent, user: other_agent)
        expect(described_class.new(agent_context, task_new).create?).to be(false)
      end

      it 'denies access to task on other agent deal' do
        expect(task_policy).not_to permit(agent_context, task_for_other)
      end

      it 'denies access to task of another account' do
        expect(task_policy).not_to permit(agent_context, other_account_task)
      end
    end
  end
end
