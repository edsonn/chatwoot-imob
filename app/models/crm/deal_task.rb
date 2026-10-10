class Crm::DealTask < ApplicationRecord
  self.table_name = 'crm_deal_tasks'

  belongs_to :account
  belongs_to :deal, class_name: 'Crm::Deal', foreign_key: :crm_deal_id, inverse_of: :tasks
  belongs_to :user

  enum task_type: { visit: 0, call: 1, contract: 2, follow_up: 3 }, _prefix: :task_type

  validates :title, presence: true
  validates :due_date, presence: true
  validate :associations_belong_to_same_account

  scope :pending, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }

  def completed?
    completed_at.present?
  end

  private

  def associations_belong_to_same_account
    return if account_id.blank?

    if deal.present? && deal.account_id != account_id
      errors.add(:deal, :invalid, message: 'must belong to the same account')
    end

    return unless user_id.present? && account.present?
    return if account.account_users.exists?(user_id: user_id)

    errors.add(:user, :invalid, message: 'must belong to the same account')
  end
end
