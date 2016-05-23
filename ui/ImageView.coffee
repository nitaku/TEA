ImageView = Backbone.D3View.extend
  namespace: null
  tagName: 'div'

  initialize: () ->
    @d3el
      .attr
        class: 'ImageView'
    
    @listenTo @model, 'change:images', @render

    # create the toolbar
    bar = @d3el.append 'div'
      .attr
        class: 'bar'

    bar.append 'button'
      .text 'Previous'
      .on 'click', () =>
        if @selected_image isnt 0
          @render @selected_image-1
      .style
        color: '#555'
      .attr
        title: 'Get the previous image.'

    bar.append 'div'
      .attr
        class: 'spacer'

    bar.append 'button'
      .text 'Next'
      .on 'click', () =>
        if @selected_image < @model.attributes.images.length-1
          @render @selected_image+1
      .style
        color: '#555'
      .attr
        title: 'Get the next image.'

    svg = @d3el.append 'svg'

    # zoom behaviour
    zoomable_layer = svg.append 'g'
      .attr
        class: 'zoomable'
    zoom = d3.behavior.zoom()
      .scaleExtent([1,Infinity])
      .on 'zoom', () ->
        zoomable_layer
          .attr
            transform: "translate(#{zoom.translate()})scale(#{zoom.scale()})"
    svg.call(zoom)

  render: (image_index) ->
    images_data = @model.get 'images'
    doc_id = @model.get 'id'

    @selected_image = if typeof image_index is 'object' then 0 else image_index

    data = if images_data.length is 0 then [] else [images_data[@selected_image]]

    images = @d3el.select('.zoomable').selectAll 'image'
      .data data

    images.enter().append 'image'

    images
      .attr
        'xlink:href': (d) -> "/webvis/annotarium/data/images/#{doc_id}/#{d.id}.jpg"

    images.exit().remove()
