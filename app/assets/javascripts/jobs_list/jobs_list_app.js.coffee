window.JobsListApp = class JobsListApp extends Backbone.Model

  initialize: ->
    window.jobsList = new JobsList()

  bootstrap: ->
    # add the paragraph which will contain the add to list link or text
    addToListParagraphElements = $('<p class="add-to-list" />').appendTo('li.job div.job-options')

    # live bind to the add to list links, so the binding updates as they're added and removed
    $('p.add-to-list a').live('click', ->
      jobsList.create($(this).parents('li').data())
      return false
    )

    # if anything changes in the jobsList, then refresh the add to list links
    jobsList.bind('all', ->
      $('p.add-to-list').html('<a href="#">Add to list</a>')

      _.each(jobsList.models, (job) ->
        $("li.job[data-id='#{job.id}'] p.add-to-list").html("<span class='disabled'>Already in list</span>")
      )
    )

    # finally, extract what we've already got in localstorage
    jobsList.fetch()

    # now build out the jobs list
    jobsListContainer = $('<div class="job-bookmarks-position" />')
    $('div.search-container').after(jobsListContainer)
    jobsListContent = $('<div class="job-bookmarks" />').appendTo(jobsListContainer)

    jobsListView = new JobsListView(model: jobsList, el: jobsListContent)
    jobsListView.render()

