class AddGameIndices < ActiveRecord::Migration
  def up
    add_index :games, :name
    add_index :games, :category
  end

  def down
    remove_index :games, :name
    remove_index :games, :category
  end
end
