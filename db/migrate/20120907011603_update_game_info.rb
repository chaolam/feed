class UpdateGameInfo < ActiveRecord::Migration
  def up
    Game.find_each do |game|
      game.update_fb_info
      puts "updated #{game.name}"
    end
  end

  def down
  end
end
