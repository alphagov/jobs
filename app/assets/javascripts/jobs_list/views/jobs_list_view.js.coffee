window.JobsListView = class JobsListView extends Backbone.View

  events:
    'click p.clear-all a': 'clearAll'

  initialize: ->
    @model.bind 'add', => this.render()
    @model.bind 'remove', => this.render()

    $(@el).append('<h2>Jobs List</h2>')

    @list = $('<ul class="jobs-list" />').appendTo(@el)

    $(@el).append('<p class="hint">Save jobs here by clicking "Add to jobs list" on a job.')

    $(@el).append('<p>Copy about clearing the list on public computers.</p>')
    $(@el).append('<p class="clear-all"><a href="#">Clear List</a></p>')

    $(window).bind 'resize', => this.setHeight()

  setHeight: ->
    height = $(window).height() - 310;
    $(@list).css(maxHeight: height)

  clearAll: ->
    if confirm("Are you sure you want to remove all the saved jobs in your jobs list?")
      # this is a bit of a hack - we duplicate the array so we're not removing elements from the same array we're iterating over. Damn Javascript.
      _.each(jobsList.models.slice(0), (job) -> job.destroy())

    return false

  render: ->
    @list.empty()

    _.each(jobsList.models, (job) ->
      jobView = new JobView(model: job)
      @list.append(jobView.render().el)
    , this)

    if jobsList.models.length > 0
      $(@el).find('p.clear-all').show()
    else
      $(@el).find('p.clear-all').hide()

    this.setHeight()

    return this