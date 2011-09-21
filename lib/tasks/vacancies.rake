namespace :vacancies do

  desc "Fires off the import background tasks, using today as the run date."
  task :import => :environment do
    Vacancy.async_bulk_import(Date.today)
  end

  desc "Purge vacancies that haven't been seen for 2 days or more."
  task :purge_expired => :environment do
    Vacancy.purge_older_than(Date.yesterday)
  end

end