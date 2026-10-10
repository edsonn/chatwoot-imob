# frozen_string_literal: true

class Crm::DealPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless account_user

      base_scope = scope.where(account_id: account.id)
      return base_scope if account_user.administrator?

      base_scope.where(assignee_id: [user.id, nil])
    end
  end

  def index?
    account_user.present?
  end

  def show?
    same_account? && permitted_deal?
  end

  def create?
    return false unless account_user.present?
    return true if account_user.administrator?

    record.assignee_id.nil? || record.assignee_id == user.id
  end

  def update?
    same_account? && permitted_deal?
  end

  def move?
    update?
  end

  def won?
    update?
  end

  def lost?
    update?
  end

  def destroy?
    same_account? && account_user.administrator?
  end

  private

  def same_account?
    record.account_id == account.id
  end

  def permitted_deal?
    return true if account_user.administrator?

    record.assignee_id == user.id || record.assignee_id.nil?
  end
end
