class JobsController < ApplicationController
  include JobFormatter

  def show
    expires_in 24.hours, :public => true unless Rails.env.development?

    @job = VacancySearch.find_individual(params[:id])
    @formatted_job = format_job(@job)
    render :action => 'not_found', :status => :not_found if @job.nil?
  end

end
