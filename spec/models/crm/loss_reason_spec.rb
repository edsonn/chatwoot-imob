require 'rails_helper'

RSpec.describe Crm::LossReason, type: :model do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:name) }
  end

  context 'with associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:deals).class_name('Crm::Deal').with_foreign_key(:crm_loss_reason_id).dependent(:restrict_with_error) }
  end

  describe 'scopes' do
    let(:account) { create(:account) }
    let!(:active_reason) { create(:crm_loss_reason, account: account, active: true) }
    let!(:inactive_reason) { create(:crm_loss_reason, account: account, active: false) }

    it 'returns only active reasons in .active scope' do
      expect(described_class.active).to include(active_reason)
      expect(described_class.active).not_to include(inactive_reason)
    end
  end
end
