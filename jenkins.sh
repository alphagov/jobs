#!/bin/bash -x
source '/usr/local/lib/rvm'
bundle install --path "/home/jenkins/bundles/${JOB_NAME}" --deployment --without mac_development

echo -e "SOLR_HOST='localhost'\nDIRECTGOV_JOBS_API_AUTHENTICATION_KEY='TESTING'" >> /var/lib/jenkins/jobs/Jobs/workspace/config/initializers/config.rb

bundle exec rake db:setup
bundle exec rake db:migrate
bundle exec rake stats

# DELETE STATIC SYMLINKS AND RECONNECT...
rm /var/lib/jenkins/jobs/Jobs/workspace/public/images
rm /var/lib/jenkins/jobs/Jobs/workspace/public/javascripts
rm /var/lib/jenkins/jobs/Jobs/workspace/public/templates
rm /var/lib/jenkins/jobs/Jobs/workspace/public/stylesheets

ln -s /var/lib/jenkins/jobs/Static/workspace/public/images /var/lib/jenkins/jobs/Jobs/workspace/public/images
ln -s /var/lib/jenkins/jobs/Static/workspace/public/javascripts /var/lib/jenkins/jobs/Jobs/workspace/public/javascripts
ln -s /var/lib/jenkins/jobs/Static/workspace/public/templates /var/lib/jenkins/jobs/Jobs/workspace/public/templates
ln -s /var/lib/jenkins/jobs/Static/workspace/public/stylesheets /var/lib/jenkins/jobs/Jobs/workspace/public/stylesheets

export DISPLAY=:99
/etc/init.d/xvfb start
bundle exec rake test:units test:functionals test:integration
RESULT=$?
/etc/init.d/xvfb stop
exit $RESULT
