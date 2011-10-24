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

Add a file in config/initializers/secrets.rb containing:

    DIRECTGOV_JOBS_API_AUTHENTICATION_KEY = "YOUR-API-KEY"

How It Works
--

There is a rake task called rake vacancies:import

Run this task to begin the indexing process of jobs into the local Solr. 

You shouln't have to wait too long before a few jobs appear, and you don't need to wait for the task to
complete before using the app.

Solr is set to commit after each import, so you should get jobs in a minute or so.

When you have enough jobs to work with then abort the task.
