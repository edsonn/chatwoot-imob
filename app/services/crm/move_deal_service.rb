class Crm::MoveDealService
  class MoveError < StandardError; end

  attr_reader :deal, :target_stage, :user, :position

  def initialize(deal:, target_stage:, user: nil, position: nil)
    @deal = deal
    @target_stage = target_stage
    @user = user
    @position = position
  end

  def perform
    validate_move!

    ActiveRecord::Base.transaction do
      from_stage = deal.stage
      from_position = deal.position

      apply_stage_and_status_changes
      deal.save!

      create_activity(from_stage, from_position)

      deal
    end
  end

  private

  def validate_move!
    raise MoveError, 'Deal is required' if deal.blank?
    raise MoveError, 'Target stage is required' if target_stage.blank?

    if deal.account_id != target_stage.account_id
      raise MoveError, 'Deal and target stage must belong to the same account'
    end

    return if deal.stage.blank?
    return if deal.stage.crm_pipeline_id == target_stage.crm_pipeline_id

    raise MoveError, 'Target stage must belong to the same pipeline'
  end

  def apply_stage_and_status_changes
    deal.stage = target_stage
    deal.position = position.to_i if position.present?
    deal.last_activity_at = Time.current

    if target_stage.stage_type_won?
      deal.status = :won
      deal.closed_at ||= Time.current
    elsif target_stage.stage_type_lost?
      # TODO [Fase 2/4]: No endpoint/modal de descarte comercial, crm_loss_reason_id e loss_notes
      # deverão ser exigidos e enviados juntos para marcar a oportunidade como perdida.
      deal.status = :lost
      deal.closed_at ||= Time.current
    else
      deal.status = :open
      deal.closed_at = nil
    end
  end

  def create_activity(from_stage, from_position)
    deal.activities.create!(
      account: deal.account,
      user: user,
      activity_type: :stage_change,
      from_stage: from_stage,
      to_stage: target_stage,
      metadata: {
        from_position: from_position,
        to_position: deal.position
      }
    )
  end
end
