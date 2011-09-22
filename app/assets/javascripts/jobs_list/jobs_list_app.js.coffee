window.JobsListApp = class JobsListApp extends Backbone.Model

  initialize: ->
    window.jobsList = new JobsList()
    window.jobsList.fetch()

  bootstrap: ->
    # add add to list links to each job in the search results
    addToListParagraphElements = $('<p class="add-to-list" />').appendTo('li.job div.job-options')
    addToListLinks = $('<a href="#">Add to List</a>').appendTo(addToListParagraphElements)

    addToListLinks.click(->
      jobsList.create($(this).parents('li').data())
      return false
    )

    # now build out the jobs list
    jobsListContainer = $('<div class="job-bookmarks-position"><div class="job-bookmarks-wrapper" /></div>')
    $('div.search-container').after(jobsListContainer)
    jobsListContent = $('<div class="job-bookmarks" />').appendTo(jobsListContainer)

    jobsListView = new JobsListView(model: jobsList, el: jobsListContent)
    jobsListView.render()