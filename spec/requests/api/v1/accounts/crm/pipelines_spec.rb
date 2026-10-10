# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CRM Pipelines API', type: :request do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }

  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }

  let(:pipeline) { create(:crm_pipeline, account: account, name: 'Funil de Vendas Imobiliárias') }
  let!(:stage_1) { create(:crm_pipeline_stage, account: account, pipeline: pipeline, name: 'Novo Lead', position: 0) }
  let!(:stage_2) { create(:crm_pipeline_stage, account: account, pipeline: pipeline, name: 'Visita Agendada', position: 1) }

  let(:other_pipeline) { create(:crm_pipeline, account: other_account, name: 'Outro Funil') }

  describe 'GET /api/v1/accounts/:account_id/crm/pipelines' do
    context 'when unauthenticated' do
      it 'returns 401 unauthorized' do
        get "/api/v1/accounts/#{account.id}/crm/pipelines"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as administrator' do
      it 'returns all pipelines of the account with stages' do
        pipeline
        other_pipeline

        get "/api/v1/accounts/#{account.id}/crm/pipelines",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['payload'].length).to eq(1)
        expect(json['payload'].first['name']).to eq('Funil de Vendas Imobiliárias')
        expect(json['payload'].first['stages'].length).to eq(2)
      end
    end

    context 'when authenticated as agent' do
      it 'allows agent to list pipelines of their account' do
        pipeline

        get "/api/v1/accounts/#{account.id}/crm/pipelines",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['payload'].first['name']).to eq('Funil de Vendas Imobiliárias')
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/crm/pipelines/:id/deals' do
    let!(:deal_unassigned) { create(:crm_deal, account: account, stage: stage_1, title: 'Lead Novo Geral', assignee: nil) }
    let!(:deal_for_agent) { create(:crm_deal, account: account, stage: stage_1, title: 'Lead do Corretor A', assignee: agent) }
    let!(:deal_for_other) { create(:crm_deal, account: account, stage: stage_2, title: 'Lead do Corretor B', assignee: other_agent) }

    context 'when unauthenticated' do
      it 'returns 401 unauthorized' do
        get "/api/v1/accounts/#{account.id}/crm/pipelines/#{pipeline.id}/deals"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as administrator' do
      it 'returns all deals across all agents in the pipeline' do
        get "/api/v1/accounts/#{account.id}/crm/pipelines/#{pipeline.id}/deals",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        deal_titles = json['payload'].map { |d| d['title'] }
        expect(deal_titles).to contain_exactly('Lead Novo Geral', 'Lead do Corretor A', 'Lead do Corretor B')
      end
    end

    context 'when authenticated as agent' do
      it 'returns only unassigned deals and deals assigned to the current agent' do
        get "/api/v1/accounts/#{account.id}/crm/pipelines/#{pipeline.id}/deals",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        deal_titles = json['payload'].map { |d| d['title'] }
        expect(deal_titles).to include('Lead Novo Geral', 'Lead do Corretor A')
        expect(deal_titles).not_to include('Lead do Corretor B')
      end
    end

    context 'when accessing a pipeline from another account' do
      it 'returns 404 not found' do
        get "/api/v1/accounts/#{account.id}/crm/pipelines/#{other_pipeline.id}/deals",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
