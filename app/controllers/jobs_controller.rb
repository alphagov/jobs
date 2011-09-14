class JobsController < ApplicationController

  def show
    @job = JobSearch.find_individual(params[:id])
  end

end
