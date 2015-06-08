require 'rails_helper'

RSpec.describe "Clusters", type: :request do
  describe "GET /clusters" do
    it "works! (now write some real specs)" do
      get clusters_path
      expect(response).to have_http_status(200)
    end
  end
end
