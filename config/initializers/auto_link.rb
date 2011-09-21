# This is so we can use rel='nofollow' in auto_link.
Jobs::Application.config.after_initialize do |config|
  ActionView::Base.sanitized_allowed_attributes = 'rel'
end