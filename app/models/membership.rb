class Membership < ActiveRecord::Base
  belongs_to :cluster
  belongs_to :element
end
