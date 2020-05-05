class CreateTrainees < ActiveRecord::Migration[5.2]
  def change
    create_table :trainees do |t|
      t.string :name
      t.string :slack_name
      t.integer :row
    end
  end
end
