class CreateElements < ActiveRecord::Migration
  def change
    create_table :elements do |t|
      t.string :key, index: true
      t.text :body
      t.references :project, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
