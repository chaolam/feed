class FacebookApp
  def self.access_token
    Rails.cache.fetch('app_access_token', :expires_in=>1.day) do
      self.any_app_access_token(FBConf.app_id, FBConf.secret_key)
    end
  end
  
  def self.any_app_access_token(app_id, secret_key)
    oauth = Koala::Facebook::OAuth.new(app_id, secret_key)
    oauth.get_app_access_token
  end
end
