namespace :vacancies do

  desc "Load all job vacancies synchronously from the remote API"
  task :import => :environment do
    Vacancy.bulk_import_from_api(Date.today)
  end

  desc "Load all vacancies from the internal (development) database into Solr"
  task :import_from_database_to_solr => :environment do
    Vacancy.bulk_import_from_local_database
  end

  desc "Purge vacancies that haven't been seen for 2 days or more."
  task :purge_expired => :environment do
    Vacancy.purge_older_than(Date.yesterday)
  end

end