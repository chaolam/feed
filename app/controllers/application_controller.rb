class ApplicationController < ActionController::Base
  protect_from_forgery

protected
  def fb_user
    return @fb_token if @fb_token
    oauth = koala_oauth
    if params[:code]
      begin
        @fb_token = oauth.get_access_token(params[:code])
      rescue Exception=>e
        @fb_token = @fb_user = nil
      end
    else
      user_info = oauth.get_user_info_from_cookies(cookies)
      @fb_token = user_info && user_info['access_token']
    end
    @fb_token
  end

  def require_fb_user
    unless fb_user
      redirect_to koala_oauth.url_for_oauth_code(:permissions=>'read_stream')
    end
  end

  def koala_oauth
    Koala::Facebook::OAuth.new(FBConf.app_id, FBConf.secret_key, root_url)
  end
end
