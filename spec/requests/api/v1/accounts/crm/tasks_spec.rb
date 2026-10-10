# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CRM Deal Tasks API', type: :request do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }

  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }
  let(:other_account_user) { create(:user, account: other_account) }

  let(:pipeline) { create(:crm_pipeline, account: account) }
  let(:stage) { create(:crm_pipeline_stage, account: account, pipeline: pipeline) }

  let(:deal_for_agent) { create(:crm_deal, account: account, stage: stage, assignee: agent) }
  let(:deal_for_other) { create(:crm_deal, account: account, stage: stage, assignee: other_agent) }
  let(:other_account_deal) { create(:crm_deal, account: other_account) }

  let(:task_for_agent) do
    create(:crm_deal_task, account: account, deal: deal_for_agent, user: agent, title: 'Ligar para o cliente')
  end
  let(:task_for_other) do
    create(:crm_deal_task, account: account, deal: deal_for_other, user: other_agent, title: 'Visita agendada')
  end

  describe 'POST /api/v1/accounts/:account_id/crm/deals/:id/tasks' do
    let(:valid_params) do
      {
        task: {
          title: 'Agendar visita presencial',
          task_type: 'visit',
          due_date: 2.days.from_now.iso8601
        }
      }
    end

    context 'when unauthenticated' do
      it 'returns 401 unauthorized' do
        post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/tasks", params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as administrator' do
      it 'allows admin to create task assigned to another agent of the account' do
        params_with_user = valid_params.deep_merge(task: { user_id: other_agent.id })
        post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/tasks",
             params: params_with_user,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json['user']['id']).to eq(other_agent.id)
      end

      it 'returns 422 if admin passes user_id from another account' do
        params_external = valid_params.deep_merge(task: { user_id: other_account_user.id })
        post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/tasks",
             params: params_external,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json['error']).to match(/Task user must belong to the same account/i)
      end
    end

    context 'when authenticated as agent on own deal' do
      it 'creates a new task and logs task_created activity' do
        post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/tasks",
             params: valid_params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json['title']).to eq('Agendar visita presencial')
        expect(json['task_type']).to eq('visit')
        expect(json['user']['id']).to eq(agent.id)

        activity = deal_for_agent.activities.last
        expect(activity.activity_type).to eq('task_created')
        expect(activity.metadata['task_title']).to eq('Agendar visita presencial')
      end

      it 'returns 422 when agent passes user_id of another agent' do
        params_other = valid_params.deep_merge(task: { user_id: other_agent.id })
        post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/tasks",
             params: params_other,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json['error']).to match(/Agents can only assign tasks to themselves/i)
      end

      it 'returns 422 when agent passes user_id from another account' do
        params_external = valid_params.deep_merge(task: { user_id: other_account_user.id })
        post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/tasks",
             params: params_external,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json['error']).to match(/Agents can only assign tasks to themselves/i)
      end

      it 'returns 422 if required title is missing' do
        post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/tasks",
             params: { task: { title: '', due_date: 2.days.from_now } },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when agent attempts to create task on deal of another agent' do
      it 'returns 401 unauthorized' do
        post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_other.id}/tasks",
             params: valid_params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/crm/deals/:id/tasks/:task_id' do
    it 'allows agent to update task title' do
      patch "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/tasks/#{task_for_agent.id}",
            params: { task: { title: 'Ligar com urgência' } },
            headers: agent.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(task_for_agent.reload.title).to eq('Ligar com urgência')
    end

    it 'allows agent to complete task and logs task_completed activity' do
      now = Time.current.iso8601
      patch "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/tasks/#{task_for_agent.id}",
            params: { task: { completed_at: now } },
            headers: agent.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(task_for_agent.reload.completed_at).to be_present

      activity = deal_for_agent.activities.last
      expect(activity.activity_type).to eq('task_completed')
      expect(activity.metadata['task_id']).to eq(task_for_agent.id)
    end

    it 'returns 422 when agent tries to update task with user_id of another agent' do
      patch "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/tasks/#{task_for_agent.id}",
            params: { task: { user_id: other_agent.id } },
            headers: agent.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json['error']).to match(/Agents can only assign tasks to themselves/i)
      expect(task_for_agent.reload.user_id).to eq(agent.id)
    end

    it 'forbids agent from updating task belonging to other agent' do
      patch "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_other.id}/tasks/#{task_for_other.id}",
            params: { task: { title: 'Tentativa indevida' } },
            headers: agent.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
