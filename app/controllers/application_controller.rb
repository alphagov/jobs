require "slimmer/headers"

class ApplicationController < ActionController::Base
  include Slimmer::Headers
  helper_method :boolean_or_nil_param
  before_filter :set_analytics_headers

protected
  def boolean_or_nil_param(param)
    if param.present?
      return (param == '1' || param == 'true')
    else
      return nil
    end
  end

  def set_analytics_headers
    set_slimmer_headers(
      section:     "Jobs",
      need_id:     125,
      format:      "jobs",
      proposition: "citizen"
    )
  end
end
