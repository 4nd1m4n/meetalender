class CreateMeetalenderMeetupGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :meetalender_meetup_groups do |t|
      t.string :name
      t.integer :group_id
      t.string :approved_cities
      t.string :group_link

      t.timestamps
    end
  end
end
