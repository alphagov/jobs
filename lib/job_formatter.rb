module JobFormatter
  def format_job(doc)
    Hash.new.tap do |hash|
      hash['id'] = doc['id']
      hash['title'] = doc['title'].try(:titlecase)
      hash['employer'] = doc['employer_name'].try(:titlecase)
      hash['location'] = doc['location_name'].try(:titlecase)
      hash['latitude'] = doc['location_0_coordinate'].to_f
      hash['longitude'] = doc['location_1_coordinate'].to_f
      hash['wage'] = doc['wage_display_text'].try(:titlecase)
      hash['hours'] = doc['hours_display_text'].try(:titlecase)
      hash['description'] = view_context.auto_link(view_context.simple_format(doc['vacancy_description']))
      hash['how_to_apply'] = view_context.auto_link(view_context.simple_format(doc['how_to_apply']))
      hash['eligability_criteria']= view_context.auto_link(view_context.simple_format(doc['eligability_criteria']))
    end
  end
end
