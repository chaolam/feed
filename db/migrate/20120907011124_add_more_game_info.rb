class AddMoreGameInfo < ActiveRecord::Migration
  def up
    add_column :games, :category, :string
    add_column :games, :subcategory, :string
    add_column :games, :description, :string
    add_column :games, :daily_active_users, :integer
    add_column :games, :weekly_active_users, :integer
    add_column :games, :monthly_active_users, :integer
  end

  def down
    remove_column :games, :mobile_web_url
    remove_column :games, :category
    remove_column :games, :subcategory
    remove_column :games, :description
    remove_column :games, :daily_active_users
    remove_column :games, :weekly_active_users
    remove_column :games, :monthly_active_users
  end
end
