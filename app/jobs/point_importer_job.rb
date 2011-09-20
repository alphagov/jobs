class PointImporterJob
  @queue = :points

  def self.perform(run_date, latitude, longitude)
    results = Vacancy.fetch_vacancies_from_api(latitude, longitude)
    results.each do |vacancy_hash|
      # just queue up each result to be a new job, so we get finer grained retry and error handling
      Resque.enqueue(VacancyImporterJob, run_date, vacancy_hash)
    end
  end

end