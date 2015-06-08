require 'rails_helper'

RSpec.describe "clusters/edit", type: :view do
  before(:each) do
    @cluster = assign(:cluster, Cluster.create!(
      :name => "MyString",
      :project => nil
    ))
  end

  it "renders the edit cluster form" do
    render

    assert_select "form[action=?][method=?]", cluster_path(@cluster), "post" do

      assert_select "input#cluster_name[name=?]", "cluster[name]"

      assert_select "input#cluster_project_id[name=?]", "cluster[project_id]"
    end
  end
end
