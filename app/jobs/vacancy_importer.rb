require 'csv'

class VacancyImporter

  def self.bulk_import_from_local_database
    Vacancy.find_in_batches do |vacancies|
      begin
        vacancies.each do |vacancy|
          puts "Inserting solr document: #{vacancy.vacancy_title}"
          vacancy.send_to_solr!
        end
      rescue
        puts "*** Error inserting solr document: #{$!} #{vacancy.inspect}"
      ensure
        $solr.commit!
      end
    end
  end

  def self.bulk_import_from_api
    postcodes = CSV.read(File.join(Rails.root, 'data', 'uk.pc.ll.csv'), :headers => true)
    postcodes = postcodes.to_a # we get a Table class back from the CSV library
    postcodes.shift # lose the header

    # we shuffle so we don't keep getting results from a nearby area as we progress through
    postcodes.shuffle.each do |row|
      latitude = row[1].to_f
      longitude = row[2].to_f

      VacancyRegionImporter.new(Date.today, latitude, longitude).import
    end
  end
end
