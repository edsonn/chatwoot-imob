# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CRM Loss Reasons API', type: :request do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }

  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  let!(:active_reason_1) { create(:crm_loss_reason, account: account, name: 'Preço fora do orçamento', active: true) }
  let!(:active_reason_2) { create(:crm_loss_reason, account: account, name: 'Imóvel indisponível', active: true) }
  let!(:inactive_reason) { create(:crm_loss_reason, account: account, name: 'Motivo antigo', active: false) }
  let!(:other_account_reason) { create(:crm_loss_reason, account: other_account, name: 'Outra Imobiliária') }

  describe 'GET /api/v1/accounts/:account_id/crm/loss_reasons' do
    context 'when unauthenticated' do
      it 'returns 401 unauthorized' do
        get "/api/v1/accounts/#{account.id}/crm/loss_reasons"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as administrator' do
      it 'returns only active loss reasons of the account' do
        get "/api/v1/accounts/#{account.id}/crm/loss_reasons",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        names = json['payload'].map { |r| r['name'] }
        expect(names).to contain_exactly('Preço fora do orçamento', 'Imóvel indisponível')
        expect(names).not_to include('Motivo antigo', 'Outra Imobiliária')
      end
    end

    context 'when authenticated as agent' do
      it 'allows agent to list active loss reasons of the account' do
        get "/api/v1/accounts/#{account.id}/crm/loss_reasons",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        names = json['payload'].map { |r| r['name'] }
        expect(names).to include('Preço fora do orçamento')
      end
    end
  end
end
