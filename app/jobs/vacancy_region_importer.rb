class VacancyRegionImporter

  def initialize(import_date, latitude, longitude)
    @import_date = import_date
    @latitude = latitude
    @longitude = longitude
  end

  def import
    VacancyApiClient.fetch_all_vacancies_from_api(@latitude, @longitude).each do |vacancy_hash|
      create_vacancy(vacancy_hash)
    end
  end

  private
  def create_vacancy(vacancy_hash)
    begin
      vacancy_hash.recursively_symbolize_keys!
      vacancy = Vacancy.find_or_initialize_by_vacancy_id(vacancy_hash[:vacancy_id])
      # if we've already seen this vacancy on this import_date, we can ignore it.
      if vacancy.most_recent_import_on == @import_date
        Rails.logger.warn "Duplicate job seen for #{@import_date} in #{vacancy.inspect}"
        return
      end

      if vacancy.new_record?
        vacancy.first_import_on = @import_date
        vacancy.most_recent_import_on = @import_date
        vacancy.import_details_from_hash(vacancy_hash)

        Rails.logger.info("Importing vacancy: #{vacancy.inspect}")

        # Imports details for a vacancy - if the vacancy is old, it's possible the API might
        # not be able to find it.
        begin
          extra_details = fetch_details_from_api(vacancy)
          if extra_details
            vacancy.employer_name = extra_details[:employer_name]
            vacancy.eligability_criteria = extra_details[:eligability_criteria]
            vacancy.vacancy_description = extra_details[:vacancy_description]
            vacancy.how_to_apply = extra_details[:how_to_apply]
          end
        rescue
          Rails.logger.error("Couldn't fetch extra details for vacancy: #{vacancy.inspect}")
        end
        vacancy.save!
      else
        vacancy.most_recent_import_on = @import_date
        vacancy.save!
      end
    rescue
      Rails.logger.error("An error occurred processing a vacancy: #{$!} #{vacancy_hash.inspect}")
    end
  end
end