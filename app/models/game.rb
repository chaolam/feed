class Game < ActiveRecord::Base
  has_many :mygames, :dependent=>:destroy

  def self.get_by_app_id(app_id, access_token=nil)
    game = self.find_by_app_id(app_id)
    return game if game
    graph = Koala::Facebook::API.new(access_token)
    result = graph.api("/#{app_id}")
    return nil unless result
    raise "no logo_url" if result['logo_url'].blank?
    game = Game.new(:app_id=>app_id)
    result.delete('id')
    result = result.delete_if {|k,v| !game.attributes.keys.include?(k)}
    game.update_attributes(result)
    game
  end
end
