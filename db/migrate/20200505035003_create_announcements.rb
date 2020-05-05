class CreateAnnouncements < ActiveRecord::Migration[5.2]
  def change
    create_table :announcements do |t|
      t.string :name
      t.string :channel
      t.string :ts
      t.integer :column
    end
  end
end
