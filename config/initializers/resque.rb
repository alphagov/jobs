# This is a bit of a hack.
# Resque uses forking before each job runs. This means our cached soap_client
# in Vacancy isn't persisted between jobs, meaning it makes a call to fetch the
# WSDL file before every API call. If we force it to make an API call here, then
# the fork will contain the cached variable and won't do this.
Resque.before_first_fork do
  Vacancy.fetch_vacancies_from_api(51.0, 1.0)
end