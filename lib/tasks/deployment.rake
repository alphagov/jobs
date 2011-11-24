namespace :deployment do
  task :router_environment do
    Bundler.require :router, :default

    require 'logger'
    logger = Logger.new STDOUT
    logger.level = Logger::DEBUG

    http = Router::HttpClient.new "http://cache.cluster:8080/router", logger

    @router = Router::Client.new http
  end

  task :register_application => :router_environment do
    platform = ENV['FACTER_govuk_platform']
    url = "http://jobs.#{platform}.alphagov.co.uk/"
    begin
      @router.applications.create application_id: "jobs", backend_url: url
    rescue Router::Conflict
      application = @router.applications.find "jobs"
      puts "Application already registered: #{application.inspect}"
    end
  end

  task :register_routes => :router_environment do
    begin
      @router.routes.create application_id: "jobs", route_type: :prefix,
        incoming_path: "/job-search"
    rescue Router::Conflict
      route = @router.routes.find "/job-search"
      puts "Route already registered: #{route.inspect}"
    end

    begin
      @router.routes.create application_id: "jobs", route_type: :prefix,
        incoming_path: "/jobs"
    rescue Router::Conflict
      route = @router.routes.find "/jobs"
      puts "Route already registered: #{route.inspect}"
    end
  end

  desc "Register jobs application and routes with the router (run in cluster)"
  task :register => [ :register_application, :register_routes ]
end
