# frozen_string_literal: true

class Api::V1::Accounts::Crm::LossReasonsController < Api::V1::Accounts::Crm::BaseController
  def index
    @loss_reasons = Current.account.crm_loss_reasons.active.order(created_at: :asc)
  end
end
