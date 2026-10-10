class Crm::PipelineStage < ApplicationRecord
  self.table_name = 'crm_pipeline_stages'

  belongs_to :account
  belongs_to :pipeline, class_name: 'Crm::Pipeline', foreign_key: :crm_pipeline_id, inverse_of: :stages
  has_many :deals, class_name: 'Crm::Deal', foreign_key: :crm_pipeline_stage_id, dependent: :restrict_with_error, inverse_of: :stage

  enum stage_type: { open: 0, won: 1, lost: 2 }, _prefix: :stage_type

  validates :name, presence: true
  validates :color, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }
  validate :pipeline_belongs_to_same_account

  private

  def pipeline_belongs_to_same_account
    return if pipeline.blank? || account_id.blank?
    return if pipeline.account_id == account_id

    errors.add(:pipeline, :invalid, message: 'must belong to the same account')
  end
end
