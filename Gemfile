source 'http://rubygems.org'

gem 'rails', '3.1.0'
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
gem 'resque'
gem 'resque-jobs-per-fork'

if ENV['SLIMMER_DEV']
  gem 'slimmer', :path => '../slimmer'
else
  gem 'slimmer', :git => 'git@github.com:alphagov/slimmer.git'
end

group :mac_development do
  gem 'guard'
  gem 'guard-test'
  gem 'growl_notify'
  gem 'rb-fsevent'
  gem 'ruby-prof'
end

group :test do
  gem 'factory_girl_rails'
  gem 'mocha', :require => false
  gem 'simplecov', :require => false
  gem 'simplecov-rcov', :require => false
  gem 'webmock', :require => false
  gem 'ci_reporter', :require => false
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', "  ~> 3.1.0"
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier'
end
