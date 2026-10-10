# frozen_string_literal: true

class Api::V1::Accounts::Crm::PipelinesController < Api::V1::Accounts::Crm::BaseController
  before_action :set_pipeline, only: [:deals]

  def index
    @pipelines = Current.account.crm_pipelines.order(position: :asc).includes(:stages)
  end

  def deals
    @deals = policy_scope(Current.account.crm_deals)
             .where(crm_pipeline_stage_id: @pipeline.stages.select(:id))
             .order(position: :asc)
             .includes(:contact, :conversation, :assignee, :loss_reason, :tasks, activities: [:user, :from_stage, :to_stage])
  end

  private

  def set_pipeline
    @pipeline = Current.account.crm_pipelines.find(params[:id])
  end
end
