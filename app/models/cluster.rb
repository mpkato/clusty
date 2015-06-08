class Cluster < ActiveRecord::Base
  belongs_to :project
  has_many :memberships
  has_many :elements, through: :memberships
end
