class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.integer :facebook_uid, :limit=>8
      t.boolean :deleted, :default=>false

      t.timestamps
    end
  end
end
