class Element < ActiveRecord::Base
  belongs_to :project
  has_many :memberships
  has_many :clusters, through: :memberships

  def self.new_from_row(row)
    self.new(key: row[0], body: row[1])
  end
end
