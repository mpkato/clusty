json.array!(@clusters) do |cluster|
  json.extract! cluster, :id, :name, :project_id
  json.url cluster_url(cluster, format: :json)
end
