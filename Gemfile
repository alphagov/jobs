source 'http://rubygems.org'

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
  gem 'sass-rails', "  ~> 3.1.0"
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier'
end
