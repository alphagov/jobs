require 'test_helper'

class JobTest < ActiveSupport::TestCase
  test "is invalid without a vacancy_id" do
    job = Factory.build(:job, :vacancy_id => nil)
    assert_equal false, job.valid?
  end

  test "to_solr_document" do
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
    document.add_field 'received_on', Date.today.beginning_of_day.iso8601

    assert_equal job.to_solr_document.xml, document.xml
  end

  test 'send_to_solr' do
    job = Factory.build(:job)
    job.stubs(:to_solr_document).returns(mock())
    $solr.expects(:update!).with(job.to_solr_document).returns(true)
    assert_equal true, job.send_to_solr
  end

  test 'delete_from_solr' do
    job = Factory.build(:job)
    $solr.expects(:delete).with(job.vacancy_id).returns(true)
    assert_equal true, job.delete_from_solr
  end
end