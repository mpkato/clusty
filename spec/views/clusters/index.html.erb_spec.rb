require 'rails_helper'

RSpec.describe "clusters/index", type: :view do
  before(:each) do
    assign(:clusters, [
      Cluster.create!(
        :name => "Name",
        :project => nil
      ),
      Cluster.create!(
        :name => "Name",
        :project => nil
      )
    ])
  end

  it "renders a list of clusters" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
  end
end
