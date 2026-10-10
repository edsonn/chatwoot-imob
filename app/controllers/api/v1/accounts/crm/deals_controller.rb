# frozen_string_literal: true

class Api::V1::Accounts::Crm::DealsController < Api::V1::Accounts::Crm::BaseController
  before_action :set_deal, only: [:show, :update, :move, :won, :lost]
  before_action :authorize_deal, only: [:show, :update, :move, :won, :lost]

  def show; end

  def create
    create_params = deal_create_params
    return unless validate_assignee_assignment!(create_params[:assignee_id]) if create_params.key?(:assignee_id)

    @deal = Current.account.crm_deals.new(create_params)
    authorize @deal

    @deal.save!
    render :show, status: :created
  end

  def update
    update_params = deal_update_params
    return unless validate_assignee_assignment!(update_params[:assignee_id]) if update_params.key?(:assignee_id)

    @deal.update!(update_params)
    render :show
  end

  def move
    target_stage = resolve_target_stage
    @deal = Crm::MoveDealService.new(
      deal: @deal,
      target_stage: target_stage,
      user: Current.user,
      position: params[:position]
    ).perform

    render :show
  rescue Crm::MoveDealService::MoveError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def won
    @deal = Crm::WonDealService.new(
      deal: @deal,
      user: Current.user,
      params: won_params
    ).perform

    render :show
  rescue Crm::WonDealService::WonError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def lost
    @deal = Crm::LostDealService.new(
      deal: @deal,
      user: Current.user,
      params: lost_params
    ).perform

    render :show
  rescue Crm::LostDealService::LostError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_deal
    @deal = Current.account.crm_deals.find(params[:id])
  end

  def authorize_deal
    case action_name
    when 'move' then authorize @deal, :move?
    when 'won'  then authorize @deal, :won?
    when 'lost' then authorize @deal, :lost?
    else authorize @deal
    end
  end

  def validate_assignee_assignment!(assignee_id)
    return true if assignee_id.blank?

    if Current.account_user.agent? && assignee_id.to_i != Current.user.id
      render json: { error: 'Agents can only assign deals to themselves or leave them unassigned' }, status: :unprocessable_entity
      return false
    end

    if Current.account_user.administrator? && !Current.account.account_users.exists?(user_id: assignee_id)
      render json: { error: 'Assignee must belong to the same account' }, status: :unprocessable_entity
      return false
    end

    true
  end

  def resolve_target_stage
    stage_id = params[:crm_pipeline_stage_id] || params[:stage_id]
    Current.account.crm_pipeline_stages.find_by(id: stage_id)
  end

  def deal_params_hash
    params[:deal].present? ? params.require(:deal) : params
  end

  def deal_create_params
    p = deal_params_hash.permit(
      :title, :value, :currency, :crm_pipeline_stage_id, :stage_id,
      :contact_id, :conversation_id, :assignee_id, :priority,
      :business_type, :source, :next_action, :next_action_at, :position,
      custom_attributes: {}
    )
    p[:crm_pipeline_stage_id] ||= p.delete(:stage_id) if p[:stage_id].present?
    p.delete(:stage_id)
    p
  end

  def deal_update_params
    p = deal_params_hash.permit(
      :title, :value, :currency, :crm_pipeline_stage_id, :stage_id,
      :contact_id, :conversation_id, :assignee_id, :priority,
      :business_type, :source, :next_action, :next_action_at, :position,
      custom_attributes: {}
    )
    p[:crm_pipeline_stage_id] ||= p.delete(:stage_id) if p[:stage_id].present?
    p.delete(:stage_id)
    p
  end

  def won_params
    params.permit(:final_value, :closed_at, :crm_pipeline_stage_id, :stage_id)
  end

  def lost_params
    params.permit(:crm_loss_reason_id, :loss_notes, :closed_at, :crm_pipeline_stage_id, :stage_id)
  end
end
