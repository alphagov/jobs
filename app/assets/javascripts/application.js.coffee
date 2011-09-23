#= require jquery_ujs
#= require modernizr-2.0.6
#= require jquery.mustache
#= require underscore-1.1.7
#= require backbone-0.5.3
#= require backbone-localstorage
#= require_tree ./jobs_list

$ ->
  if Modernizr.localstorage
    window.jobsListApp = new JobsListApp()
    jobsListApp.bootstrap()

  $('a.reset-search-form').click(->
    form = $("form.query")
    form.find(":input[name='query']").val('')
    form.find(":input[name='full_time']").val('')
    form.find(":input[name='permanent']").val('')
    form.find(":input[name='recency']").val('')
    form.submit()
    return false
  )
