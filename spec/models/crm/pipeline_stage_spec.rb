require 'rails_helper'

RSpec.describe Crm::PipelineStage, type: :model do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:color) }
    it { is_expected.to validate_numericality_of(:position).is_greater_than_or_equal_to(0) }
  end

  context 'with associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:pipeline).class_name('Crm::Pipeline').with_foreign_key(:crm_pipeline_id) }
    it { is_expected.to have_many(:deals).class_name('Crm::Deal').with_foreign_key(:crm_pipeline_stage_id).dependent(:restrict_with_error) }
  end

  context 'with enums' do
    it do
      expect(described_class.new).to define_enum_for(:stage_type)
        .with_values(open: 0, won: 1, lost: 2)
        .with_prefix(:stage_type)
    end
  end

  describe 'cross-account validation' do
    let(:account1) { create(:account) }
    let(:account2) { create(:account) }
    let(:pipeline) { create(:crm_pipeline, account: account1) }

    it 'is invalid when pipeline belongs to another account' do
      stage = build(:crm_pipeline_stage, account: account2, pipeline: pipeline)
      expect(stage).not_to be_valid
      expect(stage.errors[:pipeline]).to be_present
    end

    it 'is valid when pipeline belongs to same account' do
      stage = build(:crm_pipeline_stage, account: account1, pipeline: pipeline)
      expect(stage).to be_valid
    end
  end
end
