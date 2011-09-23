window.PrintableJobView = class PrintableJobView extends Backbone.View

  tagName: "li"

  render: ->
    $(@el).html($.mustache(@template, @model.attributes))
    console.log(@model.attributes)
    return this

  template: '''
    <article class="job">
      <h3>{{title}}</h3>
      <p>{{employer}}</p>
      <p>{{location}}</p>

      <h4>Wage</h4>
      <p>{{wage}}</p>

      <h4>Hours</h4>
      <p>{{hours}}</p>

      <h4>Description</h4>
      {{{ description }}}

      <h4>How to Apply</h4>
      {{{ how_to_apply }}}

      <h4>Eligability</h4>
      {{{ eligability_criteria }}}
    </article>
  '''
