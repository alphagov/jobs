Savon.configure do |config|
  config.log = true
  config.log_level = :debug     # changing the log level
  config.logger = Rails.logger  # using the Rails logger
end