# frozen_string_literal: true

class Api::V1::Accounts::Crm::TasksController < Api::V1::Accounts::Crm::BaseController
  before_action :set_deal
  before_action :set_task, only: [:update]

  def create
    create_params = task_params
    return unless validate_task_user_assignment!(create_params[:user_id]) if create_params.key?(:user_id)

    @task = @deal.tasks.new(create_params.merge(account: Current.account))
    @task.user ||= Current.user
    authorize @task

    ActiveRecord::Base.transaction do
      @task.save!
      create_task_activity(@task, :task_created)
    end

    render :show, status: :created
  end

  def update
    authorize @task

    update_params = task_params
    return unless validate_task_user_assignment!(update_params[:user_id]) if update_params.key?(:user_id)

    ActiveRecord::Base.transaction do
      was_completed = @task.completed?
      @task.update!(update_params)
      if !was_completed && @task.completed?
        create_task_activity(@task, :task_completed)
      end
    end

    render :show
  end

  private

  def set_deal
    deal_id = params[:deal_id] || params[:id]
    @deal = Current.account.crm_deals.find(deal_id)
  end

  def set_task
    task_id = params[:task_id] || params[:id]
    @task = @deal.tasks.find(task_id)
  end

  def validate_task_user_assignment!(assigned_user_id)
    return true if assigned_user_id.blank?

    if Current.account_user.agent? && assigned_user_id.to_i != Current.user.id
      render json: { error: 'Agents can only assign tasks to themselves' }, status: :unprocessable_entity
      return false
    end

    if Current.account_user.administrator? && !Current.account.account_users.exists?(user_id: assigned_user_id)
      render json: { error: 'Task user must belong to the same account' }, status: :unprocessable_entity
      return false
    end

    true
  end

  def task_params_hash
    params[:task].present? ? params.require(:task) : params
  end

  def task_params
    task_params_hash.permit(:title, :task_type, :due_date, :completed_at, :user_id)
  end

  def create_task_activity(task, activity_type)
    @deal.activities.create!(
      account: Current.account,
      user: Current.user,
      activity_type: activity_type,
      metadata: {
        task_id: task.id,
        task_title: task.title,
        task_type: task.task_type,
        due_date: task.due_date,
        completed_at: task.completed_at
      }
    )
  end
end
