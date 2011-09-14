FactoryGirl.define do

  factory :job do
    vacancy_id 'HAF/65144'
    vacancy_title 'DOG GROOMER'
    soc_code '6139'
    wage 'See details'
    wage_qualifier 'NK'
    wage_display_text 'NEGOTIABLE DEPENDING ON EXPERIENCE (SELF EMPLOYED)'
    wage_sort_order_id 38
    currency 'GBP'
    is_national false
    is_regional false
    hours 25
    hours_qualifier 'per week'
    hours_display_text 'HOURS TO BE ARRANGED OVER 4 DAYS'
    latitude 53.6860191671775
    longitude -1.8529497431996
    location_name 'GREETLAND, HALIFAX, W YORKS'
    is_permanent true
    first_import_at { 1.day.ago }
    most_recent_import_at { Time.now }
  end

end