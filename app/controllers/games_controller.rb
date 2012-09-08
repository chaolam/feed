class GamesController < ApplicationController
  def icon
    g = Game.get_by_app_id(params[:id])
    redirect_to g.icon_url
  rescue Exception=>e
    render(:file=>"#{Rails.root}/public/404.html", :status=>404)
  end
  
  def search
    games = params[:query].blank? ? [] : Game.search(params[:query])
    render :json=>games.collect(&:for_client)
  end
end