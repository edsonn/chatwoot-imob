require 'rails_helper'

RSpec.describe Crm::DealTask, type: :model do
  let(:account) { create(:account) }
  let(:deal) { create(:crm_deal, account: account) }
  let(:user) { create(:user) }

  before do
    create(:account_user, account: account, user: user)
  end

  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:due_date) }
  end

  context 'with associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:deal).class_name('Crm::Deal').with_foreign_key(:crm_deal_id) }
    it { is_expected.to belong_to(:user) }
  end

  context 'with enums' do
    it do
      expect(described_class.new).to define_enum_for(:task_type)
        .with_values(visit: 0, call: 1, contract: 2, follow_up: 3)
        .with_prefix(:task_type)
    end
  end

  describe 'cross-account validation' do
    let(:other_account) { create(:account) }

    it 'is invalid if deal belongs to another account' do
      other_deal = create(:crm_deal, account: other_account)
      task = build(:crm_deal_task, account: account, deal: other_deal, user: user)
      expect(task).not_to be_valid
      expect(task.errors[:deal]).to be_present
    end

    it 'is invalid if user does not belong to the account' do
      other_user = create(:user)
      task = build(:crm_deal_task, account: account, deal: deal, user: other_user)
      expect(task).not_to be_valid
      expect(task.errors[:user]).to be_present
    end
  end

  describe '#completed?' do
    it 'returns false when completed_at is nil' do
      task = build(:crm_deal_task, account: account, deal: deal, user: user, completed_at: nil)
      expect(task.completed?).to be(false)
    end

    it 'returns true when completed_at is present' do
      task = build(:crm_deal_task, account: account, deal: deal, user: user, completed_at: Time.current)
      expect(task.completed?).to be(true)
    end
  end
end
