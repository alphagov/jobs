window.JobsListView = class JobsListView extends Backbone.View

  initialize: ->
    @model.bind 'add', => this.render()

    $(@el).append('<h2>Jobs List</h2>')

    @list = $('<ul class="jobs-list" />').appendTo(@el)

    $(@el).append('<p class="hint">Save jobs here by clicking "Add to jobs list" on a job.')

    $(window).bind 'resize', => this.setHeight()

  setHeight: ->
    height = $(window).height() - 350;
    $(@list).height(height)

  render: ->
    @list.empty()

    _.each(jobsList.models, (job) ->
      jobView = new JobView(model: job)
      @list.append(jobView.render().el)
    , this)

    this.setHeight()

    return this