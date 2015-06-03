class Element < ActiveRecord::Base
  belongs_to :project

  def self.new_from_row(row)
    self.new(key: row[0], body: row[1])
  end
end
