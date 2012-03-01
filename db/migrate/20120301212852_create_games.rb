class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :app_id
      t.string :canvas_name
      t.string :icon_url
      t.string :logo_url
      t.string :mobile_web_url
      t.string :name

      t.timestamps
    end
    add_index :games, :app_id
  end
end
