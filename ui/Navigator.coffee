Navigator = Backbone.D3View.extend
  events:
    'click .item': 'on_item_clicked'

  initialize: (conf) ->
    @items = conf.items
    @selection = conf.selection

    @d3el.classed 'Navigator', true

    @listenTo @selection, 'change', @render

    @render()

  render: () ->
    listitems = @d3el.selectAll '.item'
      .data @items.models

    listitems.enter().append 'div'
      .text (d) -> d.attributes.name
      .attr
        class: 'item'

    listitems
      .classed 'selected', (d) => d.attributes.id is @selection.attributes.id

  on_item_clicked: (event, d) ->
    @selection.set
      id: d.attributes.id
