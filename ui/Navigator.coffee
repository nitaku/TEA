Navigator = Backbone.D3View.extend
  events:
    'click .item': 'on_item_clicked'

  initialize: (conf) ->
    @items = conf.items
    @selection = conf.selection

    @d3el.classed 'Navigator', true

    @listenTo @items, 'reset', @render
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
      .on 'click', () ->
        d3.selectAll '.external_link'
          .remove()

        d3.select(this).append('div')
          .attr
            class: 'external_link'
          .append('a')
            .attr
              href: (d) -> 
                external_links = [
                  "http://claviusontheweb.it/dualView/?docId=42",
                  "http://claviusontheweb.it/dualView/?docId=44",
                  "http://claviusontheweb.it/dualView/?docId=315",
                  "http://claviusontheweb.it/dualView/?docId=327",
                  "http://claviusontheweb.it/dualView/?docId=319"
                ]
                external_links[(d.attributes.name.split(' ')[1]-1)%5]
              target: '_blank'
            .style
              color: 'gray'
              'font-weight': 'normal'
            .text 'link'

  on_item_clicked: (event, d) ->
    @selection.set
      id: d.attributes.id
