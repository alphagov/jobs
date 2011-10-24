#!/bin/bash -x
bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment --without mac_development

echo -e "SOLR_HOST='localhost'\nDIRECTGOV_JOBS_API_AUTHENTICATION_KEY='TESTING'" >> config/initializers/config.rb

bundle exec rake db:setup
bundle exec rake db:migrate
bundle exec rake stats

# DELETE STATIC SYMLINKS AND RECONNECT...
for d in images javascripts templates stylesheets; do
  rm -f public/$d
  ln -s ../../../Static/workspace/public/$d public/
done

bundle exec rake ci:setup:testunit test:units test:functionals
RESULT=$?
exit $RESULT
