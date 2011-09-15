window.JobsListView = class JobsListView extends Backbone.View

  initialize: ->
    @model.bind 'add', => this.render()

    $(@el).append('<h2>Jobs List</h2>')

    @list = $('<ol class="jobs-list" />').appendTo(@el)

  render: ->
    @list.empty()

    _.each(jobsList.models, (job) ->
      jobView = new JobView(model: job)
      @list.append(jobView.render().el)
    , this)

    return this