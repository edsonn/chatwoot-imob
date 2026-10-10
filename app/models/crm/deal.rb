class Crm::Deal < ApplicationRecord
  self.table_name = 'crm_deals'

  BUSINESS_TYPES = %w[sale rental listing].freeze

  belongs_to :account
  belongs_to :stage, class_name: 'Crm::PipelineStage', foreign_key: :crm_pipeline_stage_id, inverse_of: :deals
  belongs_to :contact
  belongs_to :conversation, optional: true
  belongs_to :assignee, class_name: 'User', optional: true
  # TODO [Fase 2/4]: O endpoint/modal final de descarte exigirá crm_loss_reason_id de forma atômica.
  # Na Fase 1 o campo permanece opcional para suportar movimentações e estruturação inicial.
  belongs_to :loss_reason, class_name: 'Crm::LossReason', foreign_key: :crm_loss_reason_id, optional: true

  has_many :activities, -> { order(created_at: :desc) }, class_name: 'Crm::DealActivity', foreign_key: :crm_deal_id,
                                                         dependent: :destroy, inverse_of: :deal
  has_many :tasks, -> { order(due_date: :asc) }, class_name: 'Crm::DealTask', foreign_key: :crm_deal_id,
                                                 dependent: :destroy, inverse_of: :deal

  enum status: { open: 0, won: 1, lost: 2 }, _prefix: :status
  enum priority: { low: 0, medium: 1, high: 2, urgent: 3 }, _prefix: :priority

  validates :title, presence: true
  validates :value, numericality: { greater_than_or_equal_to: 0 }
  validates :final_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :business_type, inclusion: { in: BUSINESS_TYPES }, allow_nil: true
  validate :closed_at_presence_when_closed
  validate :associations_belong_to_same_account

  private

  def closed_at_presence_when_closed
    return unless status_won? || status_lost?
    return if closed_at.present?

    errors.add(:closed_at, :blank, message: 'must be set when status is won or lost')
  end

  def associations_belong_to_same_account
    return if account_id.blank?

    validate_stage_account
    validate_contact_account
    validate_conversation_account
    validate_assignee_account
    validate_loss_reason_account
  end

  def validate_stage_account
    return if stage.blank? || stage.account_id == account_id

    errors.add(:stage, :invalid, message: 'must belong to the same account')
  end

  def validate_contact_account
    return if contact.blank? || contact.account_id == account_id

    errors.add(:contact, :invalid, message: 'must belong to the same account')
  end

  def validate_conversation_account
    return if conversation.blank? || conversation.account_id == account_id

    errors.add(:conversation, :invalid, message: 'must belong to the same account')
  end

  def validate_assignee_account
    return if assignee_id.blank? || account.blank?
    return if account.account_users.exists?(user_id: assignee_id)

    errors.add(:assignee, :invalid, message: 'must belong to the same account')
  end

  def validate_loss_reason_account
    return if loss_reason.blank? || loss_reason.account_id == account_id

    errors.add(:loss_reason, :invalid, message: 'must belong to the same account')
  end
end
