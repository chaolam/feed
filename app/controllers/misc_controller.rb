class MiscController < ApplicationController
  def fb_channel
    response.headers['Pragma'] = 'public'
    expires_in 1.year, :public=>true
    response.headers["Expires"] = CGI.rfc1123_date(Time.now + 1.year)
    render :text=>'<script src="//connect.facebook.net/en_US/all.js"></script>' + "\n"
  end
end