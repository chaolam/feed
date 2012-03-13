class Game < ActiveRecord::Base
  has_many :mygames, :dependent=>:destroy

  def self.get_by_app_id(app_id)
    game = self.find_by_app_id(app_id)
    return game if game
    graph = Koala::Facebook::API.new
    result = graph.api("/#{app_id}")
    raise "no logo_url" if result['logo_url'].blank?
    game = Game.new(:app_id=>app_id)
    result.delete('id')
    result = result.delete_if {|k,v| !game.attributes.keys.include?(k)}
    game.update_attributes(result)
    game
  end
end
