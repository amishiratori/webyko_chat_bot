class ChangeColumnAtAnnouncements < ActiveRecord::Migration[5.2]
  def change
    change_column :announcements, :column, :string
  end
end
