class CreateMemberships < ActiveRecord::Migration
  def change
    create_table :memberships do |t|
      t.references :cluster, index: true, foreign_key: true
      t.references :element, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
