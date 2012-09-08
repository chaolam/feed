class Game < ActiveRecord::Base
  has_many :mygames, :dependent=>:destroy

  def self.get_by_app_id(app_id, access_token=nil)
    game = self.find_by_app_id(app_id)
    return game if game
    game = Game.new(:app_id=>app_id)
    if game.update_fb_info
      game
    else
      nil
    end
  end
  
  def self.search(query)
    game = Game.find_by_name(query)
    if game
      [game]
    else
      Game.find :all, :conditions=>['UPPER(name) like ?', "%#{query.upcase}%"],
        :order=>'weekly_active_users desc', :limit=>30
    end
  end
    
  def update_fb_info
    graph = Koala::Facebook::API.new
    result = graph.api("/#{app_id}")
    return false unless result
    raise "no logo_url" if result['logo_url'].blank?
    result.delete('id')
    result = result.delete_if {|k,v| !self.attributes.keys.include?(k)}
    self.update_attributes(result)
    true
  end
  
  def for_client
    {:appid=>app_id, :name=>name, :icon_url=>icon_url}
  end
end
