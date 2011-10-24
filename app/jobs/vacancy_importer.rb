class VacancyImporter

  def self.perform(run_date, latitude, longitude)
    begin
      Vacancy.fetch_vacancies_from_api(latitude, longitude).each do |vacancy_hash|
        import_vacancy(run_date, vacancy_hash)
      end
    ensure
      $solr.commit!
    end
  end

  private
  def self.import_vacancy(run_date, vacancy_hash)
    begin
      vacancy_hash.recursively_symbolize_keys!
      vacancy = Vacancy.find_or_initialize_by_vacancy_id(vacancy_hash[:vacancy_id])
      # if we've already seen this vacancy on this run_date, we can ignore it.
      return if vacancy.most_recent_import_on == run_date

      if vacancy.new_record?
        vacancy.first_import_on = run_date
        vacancy.most_recent_import_on = run_date
        vacancy.import_details_from_hash(vacancy_hash)

        Rails.logger.info("Importing vacancy: #{vacancy.inspect}")

        vacancy.import_extra_details! # makes an extra API call, which might raise an error
        vacancy.save!
        vacancy.send_to_solr!
      else
        vacancy.most_recent_import_on = run_date
        vacancy.save!
      end
    rescue
      Rails.logger.error("An error occurecd processing a vacancy: #{$!} #{vacancy_hash.inspect}")
    end
  end
end
