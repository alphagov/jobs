module Searchable
  extend ActiveSupport::Concern

  included do
    after_destroy :delete_from_solr
  end

  # Pushes into the update queue - still needs $solr.post_update! and $solr.commit!
  # to appear in the index.
  def send_to_solr
    $solr.update(self.to_solr_document)
  end

  # Immediately updates solr and tell it to commit within 5 minutes
  def send_to_solr!
    $solr.update!(self.to_solr_document, :commitWithin => 5.minutes*1000)
  end

  def delete_from_solr
    $solr.delete(self.vacancy_id)
  end

  def to_solr_document
    DelSolr::Document.new.tap do |doc|
      doc.add_field 'id', self.vacancy_id
      doc.add_field 'title', self.vacancy_title, :cdata => true
      doc.add_field 'soc_code', self.soc_code
      doc.add_field 'location', "#{self.latitude},#{self.longitude}"
      doc.add_field 'location_name', self.location_name, :cdata => true
      doc.add_field 'is_permanent', self.is_permanent
      doc.add_field 'hours', self.hours
      doc.add_field 'hours_display_text', self.hours_display_text, :cdata => true
      doc.add_field 'wage_display_text', self.wage_display_text, :cdata => true
      doc.add_field 'received_on', "#{self.received_on.try(:beginning_of_day).try(:iso8601)}Z"
      doc.add_field 'vacancy_description', self.vacancy_description, :cdata => true
      doc.add_field 'employer_name', self.employer_name, :cdata => true
      doc.add_field 'how_to_apply', self.how_to_apply, :cdata => true
      doc.add_field 'eligability_criteria', self.eligability_criteria, :cdata => true
    end
  end

  module ClassMethods
    def purge_older_than(date)
      super
      $solr.commit!
      $solr.optimize!
    end
  end
end