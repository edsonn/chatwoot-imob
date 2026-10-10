# frozen_string_literal: true

class Crm::WonDealService
  class WonError < StandardError; end

  attr_reader :deal, :user, :closed_at, :final_value, :stage_param_id, :stage

  def initialize(deal:, user: nil, params: {})
    @deal = deal
    @user = user
    @closed_at = params[:closed_at].presence || Time.current
    @final_value = params[:final_value].presence || deal&.value
    @stage_param_id = params[:crm_pipeline_stage_id] || params[:stage_id]
  end

  def perform
    validate_deal_presence!
    resolve_and_validate_stage!

    ActiveRecord::Base.transaction do
      from_stage = deal.stage
      deal.status = :won
      deal.closed_at = closed_at
      deal.final_value = final_value
      deal.stage = stage
      deal.last_activity_at = Time.current
      deal.save!

      create_activity(from_stage)

      deal
    end
  end

  private

  def validate_deal_presence!
    raise WonError, 'Deal is required' if deal.blank?
    raise WonError, 'Deal must have a current stage' if deal.stage.blank?
    raise WonError, 'Deal stage must belong to a pipeline' if deal.stage.pipeline.blank?
  end

  def resolve_and_validate_stage!
    current_pipeline = deal.stage.pipeline

    if stage_param_id.present?
      target_stage = deal.account.crm_pipeline_stages.find_by(id: stage_param_id)
      raise WonError, 'Target stage not found' if target_stage.blank?
      raise WonError, 'Stage must belong to the same account' if target_stage.account_id != deal.account_id
      raise WonError, 'Stage must belong to the same pipeline' if target_stage.crm_pipeline_id != deal.stage.crm_pipeline_id
      raise WonError, 'Stage must have stage_type won' unless target_stage.stage_type_won?

      @stage = target_stage
    else
      won_stage = current_pipeline.stages.find_by(stage_type: :won)
      raise WonError, 'Won stage not found in pipeline' if won_stage.blank?

      @stage = won_stage
    end
  end

  def create_activity(from_stage)
    deal.activities.create!(
      account: deal.account,
      user: user,
      activity_type: :status_change,
      from_stage: from_stage,
      to_stage: deal.stage,
      metadata: {
        previous_status: deal.status_before_last_save || 'open',
        new_status: 'won',
        final_value: deal.final_value
      }
    )
  end
end
