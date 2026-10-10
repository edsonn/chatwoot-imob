json.payload do
  json.array! @deals do |deal|
    json.partial! 'api/v1/accounts/crm/deals/deal', deal: deal
  end
end
