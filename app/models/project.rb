require 'csv'
class Project < ActiveRecord::Base
  belongs_to :user
  has_many :elements, dependent: :destroy

  attr_accessor :element_file

  validates :label, presence: true
  validates :element_file, presence: true, on: :create

  def read_tsv
    CSV.foreach(self.element_file.tempfile, :col_sep => "\t") do |row|
      yield row
    end
  end

  def save_with_elements
    begin
      Project.transaction do
        self.save!
        self.load_elements!
      end
    rescue Exception => e
      return false
    else
      return true
    end
  end

  def load_elements!
    begin
      raise Exception.new("Project ID is empty") if self.id.nil?
      Element.transaction do
        read_tsv do |row|
          if row.size != 2
            errors.add(:element_file, "should include exactly two columns")
            raise Exception.new("Failed to load elements")
          end
          element = Element.new_from_row(row)
          element.project_id = self.id
          element.save!
        end
      end
    rescue => e
      errors.add(:element_file, "#{e}")
      raise Exception.new("Failed to load elements: #{e}")
    end
  end

end
