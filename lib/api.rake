namespace :api do

  desc "Fires off the import background tasks, using today as the run date."
  task :import => :environment do
    Vacancy.async_bulk_import(Date.today)
  end

end