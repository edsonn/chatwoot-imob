require 'rails_helper'

RSpec.describe Crm::DealActivity, type: :model do
  let(:account) { create(:account) }
  let(:deal) { create(:crm_deal, account: account) }

  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:activity_type) }
  end

  context 'with associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:deal).class_name('Crm::Deal').with_foreign_key(:crm_deal_id) }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:from_stage).class_name('Crm::PipelineStage').optional }
    it { is_expected.to belong_to(:to_stage).class_name('Crm::PipelineStage').optional }
  end

  context 'with enums' do
    it do
      expect(described_class.new).to define_enum_for(:activity_type)
        .with_values(
          stage_change: 0,
          note: 1,
          assignment_change: 2,
          value_change: 3,
          status_change: 4,
          task_created: 5,
          task_completed: 6
        )
        .with_prefix(:activity)
    end
  end

  describe 'cross-account validation' do
    let(:other_account) { create(:account) }

    it 'is invalid if deal belongs to another account' do
      activity = build(:crm_deal_activity, account: other_account, deal: deal)
      expect(activity).not_to be_valid
      expect(activity.errors[:deal]).to be_present
    end

    it 'is valid when deal belongs to same account' do
      activity = build(:crm_deal_activity, account: account, deal: deal)
      expect(activity).to be_valid
    end
  end
end
