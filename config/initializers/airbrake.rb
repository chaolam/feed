Airbrake.configure do |config|
  config.api_key = '70be8ad1661a8b702cc60f0923aa52cc'
  config.host = 'airbrake.io'
  config.notifier_name = 'Airbrake Notifier'
  config.notifier_url = 'http://airbrake.io'
  config.user_information = 'Airbrake Error {{error_id}}'
  config.http_open_timeout = 1
  config.http_read_timeout = 3
  config.ignore_only = ["ActionController::InvalidAuthenticityToken", "ActionController::RoutingError", "ActionController::UnknownAction"]
  config.secure = false
end
