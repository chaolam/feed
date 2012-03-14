class CreateMygames < ActiveRecord::Migration
  def change
    create_table :mygames do |t|
      t.integer :game_id
      t.integer :user_id

      t.timestamps
    end
    add_index :mygames, :game_id
    add_index :mygames, :user_id
  end
end
