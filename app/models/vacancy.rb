class Vacancy < ActiveRecord::Base

  class ExtraDetailsNotFound < RuntimeError; end

  validates_presence_of :vacancy_id

  def import_details_from_hash(v)
    [:vacancy_title, :soc_code, :received_on, :wage, :wage_qualifier, 
      :wage_display_text, :wage_sort_order_id, :currency, :is_national, :is_regional,
      :hours, :hours_qualifier, :hours_display_text].each do |field|
        write_attribute(field, v[field])
    end

    self.location_name = v[:location][:location_name]
    self.location_display_name = v[:location_display_name]
    self.latitude = v[:location][:latitude].to_f
    self.longitude = v[:location][:longitude].to_f

    self.is_permanent = v[:perm_temp].downcase == 'p'
  end

  def self.purge_older_than(date)
    Vacancy.where(['most_recent_import_on < ?', date]).find_each do |vacancy|
      vacancy.destroy
    end
  end

  include Searchable
end
