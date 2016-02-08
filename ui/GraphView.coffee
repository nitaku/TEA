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
        refX: 5+R
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

    about_groups_data.forEach (g,i) ->
      g.x = 120
      g.y = 2.5*R*d3.sum(about_groups_data[0...i], (g) -> Math.max(g.spans.length,g.popairs.length))

      g.spans.forEach (s,i) ->
        s.x = 40
        s.y = g.y + 2.5*R*i
        s.parent = g

      g.popairs.forEach (p,i) ->
        p.x = 260
        p.y = g.y + 2.5*R*i
        p.parent = g

    # visualization
    about_groups = @vis.selectAll '.about_group'
      .data about_groups_data, (d) -> d.id

    enter_about_groups = about_groups.enter().append 'g'
      .attr
        class: 'about_group'

    about_links_g = enter_about_groups.append 'g'
    resource_links_g = enter_about_groups.append 'g'

    enter_about_resource = enter_about_groups.append 'g'
      .attr
        class: 'node about_resource'
        transform: (g) -> "translate(#{g.x},#{g.y})"

    enter_about_resource.append 'circle'
      .attr
        r: R

    enter_about_resource.append 'text'
      .text (d) -> "(#{d.id})"
      .attr
        class: 'label'
        dy: '0.35em'

    about_groups.exit()
      .remove()

    # about links
    about_links = about_links_g.selectAll '.about_link'
      .data (d) -> d.spans

    enter_about_links = about_links.enter().append 'path'
      .attr
        class: 'about_link link'

    about_links
      .attr
        d: (d) -> "M#{d.x} #{d.y} L#{d.parent.x} #{d.parent.y}"

    about_links.exit()
      .remove()

    # resource links
    resource_links = resource_links_g.selectAll '.resource_link'
      .data (d) -> d.popairs

    enter_resource_links = resource_links.enter().append 'path'
      .attr
        class: 'resource_link link'

    resource_links
      .attr
        d: (d) -> "M#{d.parent.x} #{d.parent.y} L#{d.x} #{d.y}"

    resource_links.exit()
      .remove()

    # spans
    spans = about_groups.selectAll '.span'
      .data (d) -> d.spans

    enter_spans = spans.enter().append 'g'
      .attr
        class: 'node span'

    enter_spans.append 'circle'
      .attr
        r: R

    enter_spans.append 'text'
      .text '< >'
      .attr
        class: 'label'
        dy: '0.35em'

    spans
      .attr
        transform: (d,i) -> "translate(#{d.x},#{d.y})"

    spans.exit()
      .remove()

    # resources
    resources = about_groups.selectAll '.resource'
      .data (d) -> d.popairs

    enter_resources = resources.enter().append 'g'
      .attr
        class: 'node resource'

    enter_resources.append 'circle'
      .attr
        r: R

    enter_as = enter_resources.append 'a'
      .attr
        class: 'valid'
        'xlink:href': (d) ->
          splitted = (''+d.object).split ':'
          if splitted[0] is 'http'
            return d.object
          else
            return prefixes[splitted[0]] + splitted[1]

    enter_as.append 'text'
      .text (d) ->
        if d.object.length > 40
          return d.object[0..15] + '...' + d.object[d.object.length-15..d.object.length]
        else
          return d.object
      .attr
        class: 'label'
        dy: '0.35em'

    resources
      .attr
        transform: (d,i) -> "translate(#{d.x},#{d.y})"

    resources.exit()
      .remove()
