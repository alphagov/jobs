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

We use Resque to manage the import process. `rake api:import` starts the process, queueing up a request for each postcode sector in the UK. We then loop through the entire country, finding the jobs nearby each request.