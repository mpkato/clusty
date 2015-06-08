require 'rails_helper'

RSpec.describe "clusters/new", type: :view do
  before(:each) do
    assign(:cluster, Cluster.new(
      :name => "MyString",
      :project => nil
    ))
  end

  it "renders new cluster form" do
    render

    assert_select "form[action=?][method=?]", clusters_path, "post" do

      assert_select "input#cluster_name[name=?]", "cluster[name]"

      assert_select "input#cluster_project_id[name=?]", "cluster[project_id]"
    end
  end
end
