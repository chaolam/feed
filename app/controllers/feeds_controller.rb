class FeedsController < ApplicationController
  before_filter :require_fb_user
  def index
    @games = fb_user.games.map {|g| g.app_id}
  end
  
end