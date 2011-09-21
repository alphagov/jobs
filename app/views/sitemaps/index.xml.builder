xml.instruct!
xml.sitemapindex({ :xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9" }) do
  @received_on_counts.each do |date, count|
    xml.sitemap do
      xml.loc sitemap_path(date)
      xml.lastmod date.beginning_of_day.iso8601
    end
  end
end