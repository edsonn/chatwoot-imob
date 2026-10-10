json.id pipeline.id
json.account_id pipeline.account_id
json.name pipeline.name
json.position pipeline.position
json.is_default pipeline.is_default
json.created_at pipeline.created_at
json.updated_at pipeline.updated_at

json.stages do
  json.array! pipeline.stages do |stage|
    json.id stage.id
    json.account_id stage.account_id
    json.crm_pipeline_id stage.crm_pipeline_id
    json.name stage.name
    json.position stage.position
    json.stage_type stage.stage_type
    json.color stage.color
    json.created_at stage.created_at
    json.updated_at stage.updated_at
  end
end
