source 'https://rubygems.org'

gem 'rails', '3.2.1'

gem 'jquery-rails', '2.0.2'
gem 'koala', '1.5.0'
gem 'mysql2', '0.3.11'

group :development, :test do
  gem 'ruby-debug19', :require => 'ruby-debug'
end

group :staging, :production do
  gem 'thin', '1.4.1'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'coffee-rails', '~> 3.2.1'
  gem 'sass-rails', '~> 3.2.3'
  gem 'uglifier', '>= 1.0.3'
end
