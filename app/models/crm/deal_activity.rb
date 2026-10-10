class Crm::DealActivity < ApplicationRecord
  self.table_name = 'crm_deal_activities'

  belongs_to :account
  belongs_to :deal, class_name: 'Crm::Deal', foreign_key: :crm_deal_id, inverse_of: :activities
  belongs_to :user, optional: true
  belongs_to :from_stage, class_name: 'Crm::PipelineStage', optional: true
  belongs_to :to_stage, class_name: 'Crm::PipelineStage', optional: true

  enum activity_type: {
    stage_change: 0,
    note: 1,
    assignment_change: 2,
    value_change: 3,
    status_change: 4,
    task_created: 5,
    task_completed: 6
  }, _prefix: :activity

  validates :activity_type, presence: true
  validate :deal_belongs_to_same_account

  private

  def deal_belongs_to_same_account
    return if deal.blank? || account_id.blank?
    return if deal.account_id == account_id

    errors.add(:deal, :invalid, message: 'must belong to the same account')
  end
end
