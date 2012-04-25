class FeedsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :require_fb_user
  
  def index
    @games = fb_user.games.map {|g| g.app_id}
  end
  
end