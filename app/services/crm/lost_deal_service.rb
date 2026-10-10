# frozen_string_literal: true

class Crm::LostDealService
  class LostError < StandardError; end

  attr_reader :deal, :user, :loss_reason_id, :loss_notes, :closed_at, :stage_param_id, :stage

  def initialize(deal:, user: nil, params: {})
    @deal = deal
    @user = user
    @loss_reason_id = params[:crm_loss_reason_id]
    @loss_notes = params[:loss_notes]
    @closed_at = params[:closed_at].presence || Time.current
    @stage_param_id = params[:crm_pipeline_stage_id] || params[:stage_id]
  end

  def perform
    validate_deal_presence!
    validate_loss_reason!
    resolve_and_validate_stage!

    ActiveRecord::Base.transaction do
      from_stage = deal.stage
      deal.status = :lost
      deal.loss_reason = loss_reason
      deal.loss_notes = loss_notes
      deal.closed_at = closed_at
      deal.stage = stage
      deal.last_activity_at = Time.current
      deal.save!

      create_activity(from_stage)

      deal
    end
  end

  private

  def validate_deal_presence!
    raise LostError, 'Deal is required' if deal.blank?
    raise LostError, 'Deal must have a current stage' if deal.stage.blank?
    raise LostError, 'Deal stage must belong to a pipeline' if deal.stage.pipeline.blank?
  end

  def loss_reason
    return @loss_reason if defined?(@loss_reason)
    return nil if deal.blank? || loss_reason_id.blank?

    @loss_reason = deal.account.crm_loss_reasons.find_by(id: loss_reason_id)
  end

  def validate_loss_reason!
    raise LostError, 'Loss reason is required' if loss_reason_id.blank?
    raise LostError, 'Invalid loss reason' if loss_reason.blank?
  end

  def resolve_and_validate_stage!
    current_pipeline = deal.stage.pipeline

    if stage_param_id.present?
      target_stage = deal.account.crm_pipeline_stages.find_by(id: stage_param_id)
      raise LostError, 'Target stage not found' if target_stage.blank?
      raise LostError, 'Stage must belong to the same account' if target_stage.account_id != deal.account_id
      raise LostError, 'Stage must belong to the same pipeline' if target_stage.crm_pipeline_id != deal.stage.crm_pipeline_id
      raise LostError, 'Stage must have stage_type lost' unless target_stage.stage_type_lost?

      @stage = target_stage
    else
      lost_stage = current_pipeline.stages.find_by(stage_type: :lost)
      raise LostError, 'Lost stage not found in pipeline' if lost_stage.blank?

      @stage = lost_stage
    end
  end

  def create_activity(from_stage)
    deal.activities.create!(
      account: deal.account,
      user: user,
      activity_type: :status_change,
      from_stage: from_stage,
      to_stage: deal.stage,
      notes: loss_notes,
      metadata: {
        previous_status: deal.status_before_last_save || 'open',
        new_status: 'lost',
        loss_reason_id: loss_reason.id,
        loss_reason_name: loss_reason.name
      }
    )
  end
end
