xml.instruct!
xml.urlset({ :xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9"}) do
  @vacancy_ids.each do |id|
    xml.url do
      xml.loc job_path(id)
      xml.lastmod @date.iso8601
    end
  end
end