# frozen_string_literal: true

class Crm::DealTaskPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless account_user

      base_scope = scope.where(account_id: account.id)
      return base_scope if account_user.administrator?

      base_scope.joins(:deal).where(
        'crm_deal_tasks.user_id = :user_id OR crm_deals.assignee_id = :user_id OR crm_deals.assignee_id IS NULL',
        user_id: user.id
      )
    end
  end

  def show?
    same_account? && permitted_task?
  end

  def create?
    return false unless same_account?
    return false unless deal_permitted?
    return true if account_user.administrator?

    record.user_id == user.id
  end

  def update?
    return false unless same_account?
    return true if account_user.administrator?

    record.user_id == user.id && deal_permitted?
  end

  def destroy?
    same_account? && (account_user.administrator? || record.user_id == user.id)
  end

  private

  def same_account?
    record.account_id == account.id
  end

  def deal_permitted?
    return true if account_user.administrator?
    return false if record.deal.blank?

    record.deal.assignee_id == user.id || record.deal.assignee_id.nil?
  end

  def permitted_task?
    return true if account_user.administrator?
    return true if record.user_id == user.id

    deal_permitted?
  end
end
