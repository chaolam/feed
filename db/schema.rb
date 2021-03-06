# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120907012040) do

  create_table "games", :force => true do |t|
    t.string   "app_id"
    t.string   "canvas_name"
    t.string   "icon_url"
    t.string   "logo_url"
    t.string   "mobile_web_url"
    t.string   "name"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.string   "category"
    t.string   "subcategory"
    t.string   "description"
    t.integer  "daily_active_users"
    t.integer  "weekly_active_users"
    t.integer  "monthly_active_users"
  end

  add_index "games", ["app_id"], :name => "index_games_on_app_id"
  add_index "games", ["category"], :name => "index_games_on_category"
  add_index "games", ["name"], :name => "index_games_on_name"

  create_table "mygames", :force => true do |t|
    t.integer  "game_id"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "mygames", ["game_id"], :name => "index_mygames_on_game_id"
  add_index "mygames", ["user_id"], :name => "index_mygames_on_user_id"

  create_table "users", :force => true do |t|
    t.integer  "facebook_uid", :limit => 8
    t.boolean  "deleted",                   :default => false
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
  end

end
