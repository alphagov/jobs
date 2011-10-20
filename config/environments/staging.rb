require File.expand_path('production.rb', File.dirname(__FILE__))

Jobs::Application.configure do
  config.action_controller.asset_host = 'staging.alphagov.co.uk:8080'
  config.action_mailer.smtp_settings = {:enable_starttls_auto => false}

  config.action_mailer.default_url_options = { :host => "jobs.staging.alphagov.co.uk:8080" }

  # swap the Slimmer middleware out for the staging configuration
  config.middleware.delete Slimmer::App
  config.middleware.use Slimmer::App, :asset_host => "http://static.staging.alphagov.co.uk"
end