namespace :router do
  task :router_environment do
    Bundler.require :router, :default

    require 'logger'
    logger = Logger.new STDOUT
    logger.level = Logger::DEBUG

    @router = Router::Client.new :logger => @logger
  end

  task :register_application => :router_environment do
    platform = ENV['FACTER_govuk_platform']
    url = "jobs.#{platform}.alphagov.co.uk/"
    @router.applications.update application_id: "jobs", backend_url: url
  end

  task :register_routes => :router_environment do
    @router.routes.update application_id: "jobs", route_type: :prefix,
      incoming_path: "/job-search"

    @router.routes.update application_id: "jobs", route_type: :prefix,
      incoming_path: "/jobs"
  end

  desc "Register jobs application and routes with the router (run this task on server in cluster)"
  task :register => [ :register_application, :register_routes ]
end
