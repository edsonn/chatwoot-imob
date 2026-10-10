require 'rails_helper'

RSpec.describe Crm::Deal, type: :model do
  let(:account) { create(:account) }

  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_numericality_of(:value).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:final_value).is_greater_than_or_equal_to(0).allow_nil }
    it { is_expected.to validate_numericality_of(:position).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_inclusion_of(:business_type).in_array(%w[sale rental listing]).allow_nil }
  end

  context 'with associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:stage).class_name('Crm::PipelineStage').with_foreign_key(:crm_pipeline_stage_id) }
    it { is_expected.to belong_to(:contact) }
    it { is_expected.to belong_to(:conversation).optional }
    it { is_expected.to belong_to(:assignee).class_name('User').optional }
    it { is_expected.to belong_to(:loss_reason).class_name('Crm::LossReason').with_foreign_key(:crm_loss_reason_id).optional }
    it { is_expected.to have_many(:activities).class_name('Crm::DealActivity').with_foreign_key(:crm_deal_id).dependent(:destroy) }
    it { is_expected.to have_many(:tasks).class_name('Crm::DealTask').with_foreign_key(:crm_deal_id).dependent(:destroy) }
  end

  context 'with enums' do
    it do
      expect(described_class.new).to define_enum_for(:status)
        .with_values(open: 0, won: 1, lost: 2)
        .with_prefix(:status)
    end

    it do
      expect(described_class.new).to define_enum_for(:priority)
        .with_values(low: 0, medium: 1, high: 2, urgent: 3)
        .with_prefix(:priority)
    end
  end

  describe 'closed_at validation' do
    it 'requires closed_at when status is won' do
      deal = build(:crm_deal, account: account, status: :won, closed_at: nil)
      expect(deal).not_to be_valid
      expect(deal.errors[:closed_at]).to be_present
    end

    it 'requires closed_at when status is lost' do
      deal = build(:crm_deal, account: account, status: :lost, closed_at: nil)
      expect(deal).not_to be_valid
      expect(deal.errors[:closed_at]).to be_present
    end

    it 'is valid without closed_at when status is open' do
      deal = build(:crm_deal, account: account, status: :open, closed_at: nil)
      expect(deal).to be_valid
    end
  end

  describe 'loss_reason behavior in Phase 1' do
    it 'is valid with status lost even if crm_loss_reason_id is nil in Phase 1' do
      deal = build(:crm_deal, account: account, status: :lost, closed_at: Time.current, loss_reason: nil)
      expect(deal).to be_valid
    end
  end

  describe 'cross-account validation' do
    let(:other_account) { create(:account) }

    it 'is invalid if stage belongs to another account' do
      other_stage = create(:crm_pipeline_stage, account: other_account)
      deal = build(:crm_deal, account: account, stage: other_stage)
      expect(deal).not_to be_valid
      expect(deal.errors[:stage]).to be_present
    end

    it 'is invalid if contact belongs to another account' do
      other_contact = create(:contact, account: other_account)
      deal = build(:crm_deal, account: account, contact: other_contact)
      expect(deal).not_to be_valid
      expect(deal.errors[:contact]).to be_present
    end

    it 'is invalid if conversation belongs to another account' do
      other_conversation = create(:conversation, account: other_account)
      deal = build(:crm_deal, account: account, conversation: other_conversation)
      expect(deal).not_to be_valid
      expect(deal.errors[:conversation]).to be_present
    end

    it 'is invalid if assignee is not a member of the account' do
      other_user = create(:user)
      deal = build(:crm_deal, account: account, assignee: other_user)
      expect(deal).not_to be_valid
      expect(deal.errors[:assignee]).to be_present
    end

    it 'is invalid if loss_reason belongs to another account' do
      other_loss_reason = create(:crm_loss_reason, account: other_account)
      deal = build(:crm_deal, account: account, loss_reason: other_loss_reason)
      expect(deal).not_to be_valid
      expect(deal.errors[:loss_reason]).to be_present
    end
  end
end
