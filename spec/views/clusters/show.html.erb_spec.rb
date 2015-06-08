require 'rails_helper'

RSpec.describe "clusters/show", type: :view do
  before(:each) do
    @cluster = assign(:cluster, Cluster.create!(
      :name => "Name",
      :project => nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(//)
  end
end
