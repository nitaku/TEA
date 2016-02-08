R = 14
prefixes =
  rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
  owl: 'http://www.w3.org/2002/07/owl#'
  rdfs: 'http://www.w3.org/2000/01/rdf-schema#'
  foaf: 'http://xmlns.com/foaf/0.1/'
  dbo: 'http://dbpedia.org/ontology/'
  dbr: 'http://dbpedia.org/resource/'
  wiki: 'http://en.wikipedia.org/wiki/'

GraphView = Backbone.D3View.extend
  initialize: () ->
    # store current pixel width and height
    @width = @el.getBoundingClientRect().width
    @height = @el.getBoundingClientRect().height

    @d3el.classed 'GraphView', true

    @defs = @d3el.append 'defs'

    # zoom support
    zoomable_layer = @d3el.append 'g'
    zoom = d3.behavior.zoom()
      .scaleExtent([-Infinity,Infinity])
      .on 'zoom', () ->
        zoomable_layer
          .attr
            transform: "translate(#{zoom.translate()})scale(#{zoom.scale()})"
    @d3el.call zoom

    @vis = zoomable_layer.append 'g'
      .attr
        transform: "translate(#{2.5*R},#{2.5*R})"

    ### define arrow markers for graph links ###
    @defs.append('marker')
      .attr
        id: 'end-arrow'
        viewBox: '0 0 10 10'
        refX: 10+R
        refY: 5
        orient: 'auto'
    .append('path')
      .attr
        d: 'M0,0 L0,10 L10,5 z'

    @listenTo @model, 'change:graph', @render

  render: () ->
    about_nodes = {}

    @model.abouts.forEach (d) =>
      if d.id not of about_nodes
        about_nodes[d.id] = {
          id: d.id,
          spans: [{
            content: @model.plain_text[d.span.start...d.span.end]
          }],
          popairs: []
        }
      else
        about_nodes[d.id].spans.push {
          content: @model.plain_text[d.span.start...d.span.end]
        }

    @model.directives.forEach (d) =>
      if d.id not of about_nodes
        about_nodes[d.id] = {
          id: d.id,
          spans: [],
          popairs: d.popairs
        }
      else
        about_nodes[d.id].popairs = about_nodes[d.id].popairs.concat d.popairs

    # layout
    about_groups_data = Object.keys(about_nodes).map (k) -> about_nodes[k]
    max_span_y = 0
    about_groups_data.forEach (g,i) ->
      g.x = 140
      g.y = 2.5*R*d3.sum(about_groups_data[0...i], (g) -> Math.max(g.spans.length,g.popairs.length))

      g.spans.forEach (s,i) ->
        s.x = 70
        s.y = g.y + 2.5*R*i
        s.parent = g
        max_span_y = Math.max max_span_y, s.y

      g.popairs.forEach (p,i) ->
        p.x = 260
        p.y = g.y + 2.5*R*i
        p.parent = g

    spans_wo_about = @model.spans.filter((s) => not s.about?).map (s,i) => {
      x: 70,
      y: max_span_y + 2.5*R*(i+1),
      content: @model.plain_text[s.start...s.end]
    }

    # visualization
    @vis.selectAll '*'
      .remove()

    link_layer = @vis.append 'g'
    node_layer = @vis.append 'g'

    content_d = {x:0, y:0}
    content = node_layer.append 'g'
      .datum content_d
      .attr
        class: 'content node'
        transform: (d,i) -> "translate(#{d.x},#{d.y})"

    content.append 'circle'
      .attr
        r: R

    content.append 'text'
      .text 'CONTENT'
      .attr
        class: 'label'
        dy: '0.35em'

    spans_wo_about.forEach (s) ->
      # spans
      span = node_layer.append 'g'
        .datum s
        .attr
          class: 'node span'
          transform: (d,i) -> "translate(#{d.x},#{d.y})"

      span.append 'circle'
        .attr
          r: R

      span.append 'text'
        .text '< >'
        .attr
          class: 'label'
          dy: '0.35em'

      # locus links
      link_layer.append 'path'
        .datum s
        .attr
          class: 'locus_link link'
          d: (d) -> "M#{d.x} #{d.y} L#{content_d.x} #{content_d.y}"

    about_groups_data.forEach (g) ->
      g.spans.forEach (s) ->
        # spans
        span = node_layer.append 'g'
          .datum s
          .attr
            class: 'node span'
            transform: (d,i) -> "translate(#{d.x},#{d.y})"

        span.append 'circle'
          .attr
            r: R

        span.append 'text'
          .text '< >'
          .attr
            class: 'label'
            dy: '0.35em'

        # locus links
        link_layer.append 'path'
          .datum s
          .attr
            class: 'locus_link link'
            d: (d) -> "M#{d.x} #{d.y} L#{content_d.x} #{content_d.y}"

        # about links
        link_layer.append 'path'
          .datum s
          .attr
            class: 'about_link link'
            d: (d) -> "M#{d.x} #{d.y} L#{d.parent.x} #{d.parent.y}"

      # about resources
      about_resource = node_layer.append 'g'
        .datum g
        .attr
          class: 'node about_resource'
          transform: (g) -> "translate(#{g.x},#{g.y})"

      about_resource.append 'circle'
        .attr
          r: R

      about_resource.append 'text'
        .text (d) -> "(#{d.id})"
        .attr
          class: 'label'
          dy: '0.35em'

      g.popairs.forEach (p) ->
        # resources
        resource = node_layer.append 'g'
          .datum p
          .attr
            class: 'node resource'
            transform: (d,i) -> "translate(#{d.x},#{d.y})"

        resource.append 'circle'
          .attr
            r: R

        a = resource.append 'a'
          .attr
            class: 'valid'
            target: '_blank'
            'xlink:href': (d) ->
              splitted = (''+d.object).split ':'
              if splitted[0] is 'http'
                return d.object
              else
                return prefixes[splitted[0]] + splitted[1]

        a.append 'text'
          .text (d) ->
            if d.object.length > 40
              return d.object[0..15] + '...' + d.object[d.object.length-15..d.object.length]
            else
              return d.object
          .attr
            class: 'label'
            dy: '0.35em'

        # predicate link
        link_layer.append 'path'
          .datum p
          .attr
            class: 'resource_link link'
            d: (d) -> "M#{d.parent.x} #{d.parent.y} L#{d.x} #{d.y}"

        link_layer.append 'text'
          .datum p
          .text (p) -> p.predicate
          .attr
            class: 'link_label'
            transform: (d) -> "translate(#{(d.parent.x+d.x)/2} #{(d.parent.y+d.y)/2}) rotate(#{ Math.atan2((d.y-d.parent.y),(d.x-d.parent.x))/Math.PI/2*360 }) translate(0,-5)"
