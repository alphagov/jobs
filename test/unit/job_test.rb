# coding:utf-8

require 'test_helper'

class JobTest < ActiveSupport::TestCase
  test 'is invalid without a vacancy_id' do
    job = Factory.build(:job, :vacancy_id => nil)
    assert_equal false, job.valid?
  end

  test '.to_solr_document' do
    job = Factory.build(:job,
      :vacancy_id => "TES/1234",
      :vacancy_title => "Testing Job",
      :soc_code => "1234",
      :latitude => 51.0,
      :longitude => 1.0,
      :location_name => "Testing Town, County",
      :is_permanent => true,
      :hours => 25,
      :hours_display_text => "25 hours, flexible working",
      :wage_display_text => "Lots of cash",
      :vacancy_description => "Work for us",
      :employer_name => "Alphagov",
      :how_to_apply => "Send us an email",
      :received_on => Date.today
    )

    document = DelSolr::Document.new
    document.add_field 'id', "TES/1234"
    document.add_field 'title', "Testing Job", :cdata => true
    document.add_field 'soc_code', '1234'
    document.add_field 'location', [51.0, 1.0].join(",")
    document.add_field 'location_name', "Testing Town, County", :cdata => true
    document.add_field 'is_permanent', true
    document.add_field 'hours', 25
    document.add_field 'hours_display_text', "25 hours, flexible working", :cdata => true
    document.add_field 'wage_display_text', "Lots of cash", :cdata => true
    document.add_field 'received_on', Date.today.beginning_of_day.iso8601
    document.add_field 'vacancy_description', "Work for us", :cdata => true
    document.add_field 'employer_name', "Alphagov", :cdata => true
    document.add_field 'how_to_apply', 'Send us an email', :cdata => true

    assert_equal job.to_solr_document.xml, document.xml
  end

  test '.send_to_solr' do
    job = Factory.build(:job)
    job.stubs(:to_solr_document).returns(mock())
    $solr.expects(:update).with(job.to_solr_document).returns(true)
    assert_equal true, job.send_to_solr
  end

  test '.send_to_solr!' do
    job = Factory.build(:job)
    job.stubs(:to_solr_document).returns(mock())
    $solr.expects(:update!).with(job.to_solr_document).returns(true)
    assert_equal true, job.send_to_solr!
  end

  test '.delete_from_solr' do
    job = Factory.build(:job)
    $solr.expects(:delete).with(job.vacancy_id).returns(true)
    assert_equal true, job.delete_from_solr
  end

  test '#fetch_vacancies_from_api' do
    job = Factory.create(:job, :vacancy_id => "SOM/56416")

    vacancy_body = {
      :age_exempt=>"N",
      :closing_date=>"30092011",
      :date_received=>"16092011",
      :disability_exempt=>"N",
      :disability_friendly=>"Y",
      :eligibility_criteria=>"Children, Elderly and Infirm",
      :employer_email=>nil,
      :employer_name=>"University of Southampton",
      :employer_ref_number=>"046911EW",
      :end_date=>nil,
      :es_vacancy=>"Y",
      :evenings=>"Not Known",
      :hours=>"35",
      :hours_display_text=>"full time, days and times to be arranged",
      :hours_qualifier=>"per week",
      :how_to_apply=>"You can apply for this job by visiting www.jobs.soton.ac.uk and following the instructions on the webpage.",
      :location=>"Southampton, Hampshire",
      :national_min_wage_exempt=>"0",
      :nights=>"Not Known",
      :open_file=>"Y",
      :pension_detail=>"No details held",
      :perm_temp=>"P",
      :postcode=>"SO17 1BJ",
      :race_exempt=>"N",
      :religion_or_belief_exempt=>"N",
      :required_experience=>"None",
      :required_skill_level=>nil,
      :restrictions=>nil,
      :sex_exempt=>"N",
      :sex_exempt_gender=>nil,
      :sexual_orientation_exempt=>"N",
      :soc_code=>"6211",
      :special_groups=>"No",
      :start_date=>nil,
      :termtimes=>"N",
      :vacancy_description=>"The post holder should be qualified to A Level/HNC/NVQ3 or equivalent. Holding a Life Guarding NVQ/NPLQ Level 3 or equivalent and First Aid qualification is essential, as is being a Member of Register of Exercise Professionals Level 3 or equivalent. Relevant supervisory experience in the fitness and leisure industry is an advantage along with expert .  knowledge in a chosen field of specialism. The successful candidates will be part of a highly motivated and organised Sport and Wellbeing team responsible for ensuring safe and efficient daily operation of the facilities, meeting accredited standards, and ensuring that our customers are advised or supported during their leisure activities, classes, courses or instruction. Successful applicants are required to provide an enhanced disclosure. Disclosure expense will be met by employer.  Please apply online through www.jobs.soton.ac.ukor alternatively telephone 023 8059 2750 for an application form.",
      :vacancy_id=>"SOM/56416",
      :vacancy_messages=> {
        :vacancy_message=>[
          {:message=>"If you are looking for work, Tax Credits could top up your earnings"},
          {:message=>"All successful candidates will be vetted by the employer prior to taking up appointment."},
          {:message=>"This vacancy meets the requirements of the National Minimum Wage Act"},
          {:message=>"If you are unable to apply for the job advertised by the method displayed, due to a health condition or disability, please contact Jobcentre Plus for further assistance."},
          {:message=>"Jobcentre Plus cannot be responsible for or accept liability for the content of any displayed website addresses.  Any inclusion to an external website from Jobcentre Plus must not be interpreted as an endorsement of that site, product or services it provides."}
        ]
      },
      :vacancy_title=>"Sports and Wellbeing Supervisor - 046911",
      :wage=>"See details",
      :wage_display_text=>"£22,325 - £26,629 per annum",
      :wage_qualifier=>"NK",
      :weekends=>"Not Known",
      :work_times=>"full time, days and times to be arranged"
    }

    body = {
      :get_job_detail_response => {
        :get_job_detail_result => {
          :vacancy => vacancy_body
        }
      }
    }

    response = mock
    response.stubs(:body => body)

    Job.soap_client.stubs(:request).raises(Timeout::Error).then.returns(response)
    assert_equal job.fetch_details_from_api, vacancy_body

    Job.soap_client.stubs(:request).returns(response)
    assert_equal job.fetch_details_from_api, vacancy_body

    Job.soap_client.stubs(:request).raises(Timeout::Error).then.raises(Timeout::Error).then.raises(Timeout::Error)
    assert_raises(Timeout::Error) { job.fetch_details_from_api }
  end


end