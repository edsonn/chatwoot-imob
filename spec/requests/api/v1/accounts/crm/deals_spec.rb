# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CRM Deals API', type: :request do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }

  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }
  let(:other_account_user) { create(:user, account: other_account) }

  let(:pipeline) { create(:crm_pipeline, account: account) }
  let(:other_pipeline) { create(:crm_pipeline, account: account) }

  let(:stage_open_1) { create(:crm_pipeline_stage, account: account, pipeline: pipeline, position: 0, stage_type: :open) }
  let(:stage_open_2) { create(:crm_pipeline_stage, account: account, pipeline: pipeline, position: 1, stage_type: :open) }
  let(:stage_won) { create(:crm_pipeline_stage, :won, account: account, pipeline: pipeline, position: 2) }
  let(:stage_lost) { create(:crm_pipeline_stage, :lost, account: account, pipeline: pipeline, position: 3) }

  let(:other_pipeline_stage) { create(:crm_pipeline_stage, account: account, pipeline: other_pipeline, stage_type: :won) }

  let(:contact) { create(:contact, account: account) }
  let(:loss_reason) { create(:crm_loss_reason, account: account, name: 'Preço fora do perfil') }
  let(:other_loss_reason) { create(:crm_loss_reason, account: other_account) }
  let(:other_stage) { create(:crm_pipeline_stage, account: other_account) }

  let(:deal_unassigned) do
    create(:crm_deal, account: account, stage: stage_open_1, contact: contact, assignee: nil, title: 'Lead sem Dono')
  end
  let(:deal_for_agent) do
    create(:crm_deal, account: account, stage: stage_open_1, contact: contact, assignee: agent, title: 'Apartamento Batel')
  end
  let(:deal_for_other) do
    create(:crm_deal, account: account, stage: stage_open_1, contact: contact, assignee: other_agent, title: 'Casa Alphaville')
  end
  let(:other_account_deal) { create(:crm_deal, account: other_account) }

  describe 'POST /api/v1/accounts/:account_id/crm/deals' do
    let(:valid_params) do
      {
        deal: {
          title: 'Casa Campo Comprido — Carlos',
          value: 750_000.0,
          currency: 'BRL',
          crm_pipeline_stage_id: stage_open_1.id,
          contact_id: contact.id,
          priority: 'high',
          business_type: 'sale',
          source: 'meta_ads',
          custom_attributes: {
            property_code: 'CA-102',
            neighborhood: 'Campo Comprido'
          }
        }
      }
    end

    context 'when unauthenticated' do
      it 'returns 401 unauthorized' do
        post "/api/v1/accounts/#{account.id}/crm/deals", params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as administrator' do
      it 'creates a new deal and returns serialized representation' do
        post "/api/v1/accounts/#{account.id}/crm/deals",
             params: valid_params,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json['id']).to be_present
        expect(json['title']).to eq('Casa Campo Comprido — Carlos')
        expect(json['value']).to eq(750_000.0)
        expect(json['contact']['id']).to eq(contact.id)
        expect(json['custom_attributes']['property_code']).to eq('CA-102')
      end

      it 'allows admin to assign deal to another agent of the same account' do
        params_with_assignee = valid_params.deep_merge(deal: { assignee_id: other_agent.id })
        post "/api/v1/accounts/#{account.id}/crm/deals",
             params: params_with_assignee,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json['assignee']['id']).to eq(other_agent.id)
      end

      it 'returns 422 if required title is missing' do
        invalid_params = valid_params.deep_merge(deal: { title: '' })
        post "/api/v1/accounts/#{account.id}/crm/deals",
             params: invalid_params,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns 422 if stage belongs to another account' do
        invalid_params = valid_params.deep_merge(deal: { crm_pipeline_stage_id: other_stage.id })
        post "/api/v1/accounts/#{account.id}/crm/deals",
             params: invalid_params,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when authenticated as agent' do
      it 'allows agent to create deal without assignee' do
        post "/api/v1/accounts/#{account.id}/crm/deals",
             params: valid_params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
      end

      it 'allows agent to create deal assigned to themselves' do
        params_self = valid_params.deep_merge(deal: { assignee_id: agent.id })
        post "/api/v1/accounts/#{account.id}/crm/deals",
             params: params_self,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json['assignee']['id']).to eq(agent.id)
      end

      it 'returns 422 when agent tries to create deal assigned to another agent' do
        params_other = valid_params.deep_merge(deal: { assignee_id: other_agent.id })
        post "/api/v1/accounts/#{account.id}/crm/deals",
             params: params_other,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json['error']).to match(/Agents can only assign deals to themselves/i)
      end

      it 'returns 422 when agent tries to create deal with assignee from another account' do
        params_external = valid_params.deep_merge(deal: { assignee_id: other_account_user.id })
        post "/api/v1/accounts/#{account.id}/crm/deals",
             params: params_external,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/crm/deals/:id' do
    it 'allows admin to view any deal in the account' do
      get "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_other.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['title']).to eq('Casa Alphaville')
    end

    it 'allows agent to view deal assigned to themselves' do
      get "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['title']).to eq('Apartamento Batel')
    end

    it 'forbids agent from viewing deal assigned to another agent' do
      get "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_other.id}",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 404 when requesting deal from another account' do
      get "/api/v1/accounts/#{account.id}/crm/deals/#{other_account_deal.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/crm/deals/:id' do
    let(:update_params) do
      {
        deal: {
          title: 'Apartamento Batel — Atualizado',
          value: 520_000.0,
          priority: 'urgent'
        }
      }
    end

    it 'allows agent to update their assigned deal' do
      patch "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}",
            params: update_params,
            headers: agent.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(deal_for_agent.reload.title).to eq('Apartamento Batel — Atualizado')
      expect(deal_for_agent.value).to eq(520_000.0)
    end

    it 'allows agent to assume unassigned deal with own user id' do
      patch "/api/v1/accounts/#{account.id}/crm/deals/#{deal_unassigned.id}",
            params: { deal: { assignee_id: agent.id } },
            headers: agent.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(deal_unassigned.reload.assignee_id).to eq(agent.id)
    end

    it 'returns 422 when agent tries to update deal passing assignee_id of another agent' do
      patch "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}",
            params: { deal: { assignee_id: other_agent.id } },
            headers: agent.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json['error']).to match(/Agents can only assign deals to themselves/i)
      expect(deal_for_agent.reload.assignee_id).to eq(agent.id)
    end

    it 'allows admin to reassign deal to another agent' do
      patch "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}",
            params: { deal: { assignee_id: other_agent.id } },
            headers: admin.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(deal_for_agent.reload.assignee_id).to eq(other_agent.id)
    end

    it 'forbids agent from updating deal assigned to another agent' do
      patch "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_other.id}",
            params: update_params,
            headers: agent.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/crm/deals/:id/move' do
    it 'moves the deal to target stage and logs activity' do
      post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/move",
           params: { crm_pipeline_stage_id: stage_open_2.id, position: 3 },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
      expect(deal_for_agent.reload.stage).to eq(stage_open_2)
      expect(deal_for_agent.position).to eq(3)

      activity = deal_for_agent.activities.last
      expect(activity.activity_type).to eq('stage_change')
      expect(activity.to_stage).to eq(stage_open_2)
    end

    it 'forbids agent from moving deal assigned to another agent' do
      post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_other.id}/move",
           params: { crm_pipeline_stage_id: stage_open_2.id },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 422 when target stage belongs to another account' do
      post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/move",
           params: { crm_pipeline_stage_id: other_stage.id },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/crm/deals/:id/won' do
    before { stage_won }

    it 'marks the deal as won with optional final_value and closed_at' do
      post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/won",
           params: { final_value: 490_000.0, crm_pipeline_stage_id: stage_won.id },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
      deal_for_agent.reload
      expect(deal_for_agent.status).to eq('won')
      expect(deal_for_agent.final_value).to eq(490_000.0)
      expect(deal_for_agent.closed_at).to be_present
      expect(deal_for_agent.stage).to eq(stage_won)

      activity = deal_for_agent.activities.last
      expect(activity.activity_type).to eq('status_change')
      expect(activity.metadata['new_status']).to eq('won')
    end

    it 'returns 422 if stage belongs to another pipeline' do
      post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/won",
           params: { crm_pipeline_stage_id: other_pipeline_stage.id },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(deal_for_agent.reload.status).to eq('open')
    end

    it 'returns 422 if stage does not have stage_type won' do
      post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/won",
           params: { crm_pipeline_stage_id: stage_open_2.id },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(deal_for_agent.reload.status).to eq('open')
    end

    it 'forbids agent from marking deal of another agent as won' do
      post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_other.id}/won",
           params: { final_value: 490_000.0 },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/crm/deals/:id/lost' do
    before { stage_lost }

    it 'marks deal as lost when valid crm_loss_reason_id is provided' do
      post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/lost",
           params: {
             crm_loss_reason_id: loss_reason.id,
             loss_notes: 'Imóvel acima do orçamento',
             crm_pipeline_stage_id: stage_lost.id
           },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
      deal_for_agent.reload
      expect(deal_for_agent.status).to eq('lost')
      expect(deal_for_agent.loss_reason).to eq(loss_reason)
      expect(deal_for_agent.loss_notes).to eq('Imóvel acima do orçamento')
      expect(deal_for_agent.closed_at).to be_present
      expect(deal_for_agent.stage).to eq(stage_lost)

      activity = deal_for_agent.activities.last
      expect(activity.activity_type).to eq('status_change')
      expect(activity.notes).to eq('Imóvel acima do orçamento')
    end

    it 'returns 422 if crm_loss_reason_id is missing' do
      post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/lost",
           params: { loss_notes: 'Faltou motivo' },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json['error']).to match(/Loss reason is required/i)
      expect(deal_for_agent.reload.status).to eq('open')
    end

    it 'returns 422 if crm_loss_reason_id belongs to another account' do
      post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/lost",
           params: { crm_loss_reason_id: other_loss_reason.id },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(deal_for_agent.reload.status).to eq('open')
    end

    it 'returns 422 if stage belongs to another pipeline' do
      post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_agent.id}/lost",
           params: { crm_loss_reason_id: loss_reason.id, crm_pipeline_stage_id: other_pipeline_stage.id },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(deal_for_agent.reload.status).to eq('open')
    end

    it 'forbids agent from marking deal of another agent as lost' do
      post "/api/v1/accounts/#{account.id}/crm/deals/#{deal_for_other.id}/lost",
           params: { crm_loss_reason_id: loss_reason.id },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
