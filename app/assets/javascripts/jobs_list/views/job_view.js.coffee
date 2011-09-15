window.JobView = class JobView extends Backbone.View

  tagName: "li"
  events:
    'click a.remove' : 'clear'

  initialize: ->
    @model.bind 'destroy', => this.removeView()

  render: ->
    $(@el).html($.mustache(@template, @model.attributes))
    return this

  removeView: ->
    $(@el).remove()

  clear: ->
    @model.destroy()
    return false

  template: '''
    <p>{{id}} - {{title}} <a href="#" class="remove">remove</a></p>
  '''