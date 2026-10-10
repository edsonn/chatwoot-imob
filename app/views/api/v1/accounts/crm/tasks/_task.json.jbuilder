json.id task.id
json.crm_deal_id task.crm_deal_id
json.title task.title
json.task_type task.task_type
json.due_date task.due_date
json.completed_at task.completed_at
json.created_at task.created_at
json.updated_at task.updated_at

if task.user.present?
  json.user do
    json.id task.user.id
    json.name task.user.name
    json.avatar_url task.user.avatar_url
  end
else
  json.user nil
end
