class ApplicationController < ActionController::Base
  protect_from_forgery

protected
  def fb_user
    return @user if @user
    oauth = koala_oauth
    user_info = oauth.get_user_info_from_cookies(cookies)
    if user_info
      @fb_token = user_info['access_token']
      @user = User.find_or_create_by_facebook_uid(user_info['user_id'])
    elsif params[:code]
      @fb_token = oauth.get_access_token(params[:code])
      graph = Koala::Facebook::GraphAPI.new(@fb_token)
      user_info = graph.api('/me')
      @user = User.find_or_create_by_facebook_uid(user_info['id'])
    end
    @user
  rescue Exception=>e
    raise e
    @user = @fb_token = nil
  end

  def require_fb_user
    unless fb_user
      redirect_to_oauth
    end
  end

  def koala_oauth
    redirect_url = url_for(:controller=>'misc', :action=>'canvas')
    Koala::Facebook::OAuth.new(FBConf.app_id, FBConf.secret_key, redirect_url)
  end
  
  def redirect_to_oauth
    @oauth_url = koala_oauth.url_for_oauth_code(:permissions=>'read_stream')
    render :layout=>'oauth'
  end
end
