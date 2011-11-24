source 'http://rubygems.org'
source 'https://gems.gemfury.com/vo6ZrmjBQu5szyywDszE/'

group :passenger_compatibility do
  gem 'rack', '1.3.5'
  gem 'rake', '0.9.2'
end

gem 'rails', '3.1.1'
gem 'sqlite3'
gem 'json'
gem 'jquery-rails'
gem 'savon'
gem 'therubyracer'
gem 'delsolr', :git => 'https://github.com/alphagov/delsolr.git'
gem 'geogov', :git => 'https://github.com/alphagov/geogov.git'
gem 'compass', '~> 0.12.alpha.0'
gem 'rails_autolink'
gem 'retry-this'
gem 'sass-rails', "  ~> 3.1.0"
gem 'mysql2'
gem 'plek', '0.1.7'
gem 'rummageable', :git => 'git@github.com:alphagov/rummageable.git'

if ENV['SLIMMER_DEV']
  gem 'slimmer', :path => '../slimmer'
else
  gem 'slimmer', :git => 'git@github.com:alphagov/slimmer.git'
end

group :test do
  gem 'factory_girl_rails'
  gem 'mocha', :require => false
  gem 'simplecov', :require => false
  gem 'simplecov-rcov', :require => false
  gem 'webmock', :require => false
  gem 'ci_reporter'
  gem 'test-unit'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier'
end

group :router do
  gem 'router-client', require: 'router/client'
end
