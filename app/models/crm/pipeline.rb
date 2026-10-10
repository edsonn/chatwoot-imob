class Crm::Pipeline < ApplicationRecord
  self.table_name = 'crm_pipelines'

  belongs_to :account
  has_many :stages, -> { order(position: :asc) }, class_name: 'Crm::PipelineStage', foreign_key: :crm_pipeline_id,
                                                  dependent: :restrict_with_error, inverse_of: :pipeline
  has_many :deals, through: :stages, class_name: 'Crm::Deal'

  validates :name, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }
end
