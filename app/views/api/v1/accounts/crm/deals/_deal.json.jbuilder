json.id deal.id
json.account_id deal.account_id
json.title deal.title
json.value deal.value.to_f
json.currency deal.currency
json.final_value deal.final_value&.to_f
json.status deal.status
json.priority deal.priority
json.business_type deal.business_type
json.source deal.source
json.position deal.position
json.next_action deal.next_action
json.next_action_at deal.next_action_at
json.closed_at deal.closed_at
json.last_activity_at deal.last_activity_at
json.custom_attributes deal.custom_attributes
json.crm_pipeline_stage_id deal.crm_pipeline_stage_id
json.created_at deal.created_at
json.updated_at deal.updated_at

if deal.stage.present?
  json.stage do
    json.id deal.stage.id
    json.name deal.stage.name
    json.color deal.stage.color
    json.position deal.stage.position
    json.stage_type deal.stage.stage_type
    json.crm_pipeline_id deal.stage.crm_pipeline_id
  end
else
  json.stage nil
end

if deal.contact.present?
  json.contact do
    json.id deal.contact.id
    json.name deal.contact.name
    json.email deal.contact.email
    json.phone_number deal.contact.phone_number
    json.thumbnail deal.contact.avatar_url
  end
else
  json.contact nil
end

if deal.conversation.present?
  json.conversation do
    json.id deal.conversation.id
    json.inbox_id deal.conversation.inbox_id
    json.status deal.conversation.status
  end
else
  json.conversation nil
end

if deal.assignee.present?
  json.assignee do
    json.id deal.assignee.id
    json.name deal.assignee.name
    json.email deal.assignee.email
    json.avatar_url deal.assignee.avatar_url
  end
else
  json.assignee nil
end

if deal.loss_reason.present?
  json.loss_reason do
    json.id deal.loss_reason.id
    json.name deal.loss_reason.name
  end
  json.loss_notes deal.loss_notes
else
  json.loss_reason nil
  json.loss_notes deal.loss_notes
end

json.tasks do
  json.array! deal.tasks do |task|
    json.partial! 'api/v1/accounts/crm/tasks/task', task: task
  end
end

json.activities do
  json.array! deal.activities do |activity|
    json.id activity.id
    json.activity_type activity.activity_type
    json.notes activity.notes
    json.metadata activity.metadata
    json.created_at activity.created_at

    if activity.user.present?
      json.user do
        json.id activity.user.id
        json.name activity.user.name
      end
    else
      json.user nil
    end

    if activity.from_stage.present?
      json.from_stage do
        json.id activity.from_stage.id
        json.name activity.from_stage.name
      end
    else
      json.from_stage nil
    end

    if activity.to_stage.present?
      json.to_stage do
        json.id activity.to_stage.id
        json.name activity.to_stage.name
      end
    else
      json.to_stage nil
    end
  end
end
