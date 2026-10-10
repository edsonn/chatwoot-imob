class Crm::LossReason < ApplicationRecord
  self.table_name = 'crm_loss_reasons'

  belongs_to :account
  has_many :deals, class_name: 'Crm::Deal', foreign_key: :crm_loss_reason_id, dependent: :restrict_with_error, inverse_of: :loss_reason

  validates :name, presence: true
  scope :active, -> { where(active: true) }
end
