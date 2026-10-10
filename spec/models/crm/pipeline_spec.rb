require 'rails_helper'

RSpec.describe Crm::Pipeline, type: :model do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_numericality_of(:position).is_greater_than_or_equal_to(0) }
  end

  context 'with associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:stages).class_name('Crm::PipelineStage').with_foreign_key(:crm_pipeline_id).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:deals).through(:stages).class_name('Crm::Deal') }
  end
end
