module SearchHelper

  def permanent_options
    {
      "Permanent" => true,
      "Temporary" => false,
      "Permanent or Temporary" => nil
    }
  end

  def time_options
    {
      "Full Time" => true,
      "Part Time" => false,
      "Full or Part Time" => nil
    }
  end

  RAD_PER_DEG = 0.017453293
  RADIUS_MILES = 3956

  def distance(latitude_1, longitude_1, latitude_2, longitude_2)
    d_longitude = longitude_2 - longitude_1
    d_latitude = latitude_2 - latitude_1

    d_longitude_rad = d_longitude * RAD_PER_DEG
    d_latitude_rad = d_latitude * RAD_PER_DEG

    latitude_1_rad = latitude_1 * RAD_PER_DEG
    longitude_1_rad = longitude_1 * RAD_PER_DEG
    latitude_2_rad = latitude_2 * RAD_PER_DEG
    longitude_2_rad = longitude_2 * RAD_PER_DEG

    a = (Math.sin(d_latitude_rad/2))**2 + Math.cos(latitude_1_rad) * Math.cos(latitude_2_rad) * (Math.sin(d_longitude_rad/2))**2
    c = 2 * Math.atan2( Math.sqrt(a), Math.sqrt(1-a))
    RADIUS_MILES * c
  end

  def search_form_fields(params)
    String.new.html_safe.tap do |string|
      params.each do |k, v|
        string << hidden_field_tag(k, v)
      end
    end
  end

end