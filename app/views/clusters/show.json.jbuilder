json.extract! @cluster, :id, :name
json.elements @cluster.elements do |element|
  json.extract! element, :id, :key, :body
end
