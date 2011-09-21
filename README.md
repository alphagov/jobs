Jobs
==

Job search for the alphagov site.

Requirements
--

* Rails 3.1
* Ruby 1.9.2
* Solr 3.3
* Redis 2.2

Configuration
--

Add a file in config/secrets.rb containing:

    DIRECTGOV_JOBS_API_AUTHENTICATION_KEY = "YOUR-API-KEY"

How It Works
--

The canonical store of vacancy information is the DirectGov Jobs API. This service pulls all of the vacancies out of that API, and stores them into an SQLite database before putting them in Solr.

Solr provides the search engine for vacancies, and is used for displaying the information about each job. SQLite isn't used as a public facing datastore: it's only an intermediary step.

We use Resque to manage the import process. `rake vacancies:import` queues up the first resque jobs: making a request for each postcode sector in the UK, and finding the vacancies nearby. These then queue up resque jobs to fetch vacancy details for each vacancy, before importing them into Solr.

To process the queue, you'll need to be running some Resque workers.

    QUEUES=vacancies,points JOBS_PER_FORK=100 COUNT=4 rake resque:workers

The order of the queues doesn't matter, but if you have it set to vacancies first, then it'll process vacancies as they're found, rather than waiting until the entire country has been swept. It also keeps the queue sizes in redis down, which could be an issue.

`JOBS_PER_FORK` is a tunable number. 100 is just an example.

The resque jobs should fail in obvious ways, ensuring that they can be retried from the resque web interface if possible.