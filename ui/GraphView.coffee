R = 18
prefixes =
  rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
  owl: 'http://www.w3.org/2002/07/owl#'
  rdfs: 'http://www.w3.org/2000/01/rdf-schema#'
  foaf: 'http://xmlns.com/foaf/0.1/'
  dbo: 'http://dbpedia.org/ontology/'
  dbr: 'http://dbpedia.org/about_resource/'
  wiki: 'http://en.wikipedia.org/wiki/'

GraphView = Backbone.D3View.extend
  initialize: () ->
    # store current pixel width and height
    @width = @el.getBoundingClientRect().width
    @height = @el.getBoundingClientRect().height

    @d3el.classed 'GraphView', true

    @vis = @d3el.append 'g'
    @defs = @d3el.append 'defs'

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
    graph = @model.get 'graph'

    ### store the node index into the node itself ###
    for n, i in graph.nodes
      n.i = i

    ### store neighbor nodes into each node ###
    for n, i in graph.nodes
      n.in_neighbors = []
      n.out_neighbors = []

    for l in graph.links
      l.source.out_neighbors.push l.target
      l.target.in_neighbors.push l.source

    ### compute longest distances ###
    topological_order = tsort(graph.links.map (l) -> [l.source.i, l.target.i])

    for n in graph.nodes
      n.longest_dist = -Infinity

    # Root nodes have no incoming links
    graph.nodes.forEach (n) ->
      if n.in_neighbors.length is 0
        n.longest_dist = switch n.type
          when 'content' then 0
          when 'about_resource' then 2

    for i in topological_order # control direction
      n = graph.nodes[i]
      for nn in n.out_neighbors # control direction
        if nn.longest_dist < n.longest_dist+1
          nn.longest_dist = n.longest_dist+1

    graph.constraints = []

    ### create the alignment contraints ###
    levels = _.uniq graph.nodes.map (n) -> n.longest_dist
    levels.sort() # this seems to be necessary
    levels.forEach (depth) ->
      graph.constraints.push {
        type: 'alignment',
        axis: 'x',
        offsets: graph.nodes.filter((n) -> n.longest_dist is depth).map (n) -> {
          node: n.i,
          offset: 0
        }
      }

    PAD_MULTIPLIER = 3.5

    ### create the position contraints ###
    levels.forEach (depth, i) ->
      if i < levels.length-1
        n1 = _.find graph.nodes, (n) -> n.longest_dist is depth
        n2 = _.find graph.nodes, (n) -> n.longest_dist is depth+1

        graph.constraints.push {
          axis: 'x',
          left: n1.i,
          right: n2.i,
          gap: if depth < 2 then 5*R else 8*R
        }

    ### create nodes and links ###
    @vis.selectAll '.link'
      .remove()
    @vis.selectAll '.node'
      .remove()
    @vis.selectAll '.link_label'
      .remove()

    links = @vis.selectAll '.link'
      .data graph.links

    enter_links = links
      .enter().append 'line'
        .attr
          class: (d) -> "link #{d.type}"

    enter_links.append 'title'
      .text (d) -> 'link'

    link_labels = @vis.selectAll '.link_label'
      .data graph.links

    link_labels.enter().append 'text'
      .text (d) ->
        if d.type is 'predicate'
          return d.predicate
        else
          return d.type
      .attr
        class: 'link_label'

    nodes = @vis.selectAll '.node'
      .data graph.nodes

    enter_nodes = nodes.enter().append 'g'
      .attr
        class: (d) -> "node #{d.type}"

    enter_nodes.append 'circle'
      .attr
        r: R

    enter_as = enter_nodes.append 'a'
      .attr
        target: '_blank'

    enter_as.filter (d) -> d.type is 'resource'
      .attr
        class: 'valid'
        'xlink:href': (d) ->
          if d.type isnt 'resource'
            return ''

          splitted = (''+d.id).split ':'
          if splitted[0] is 'http'
            return d.id
          else
            return prefixes[splitted[0]] + splitted[1]

    enter_as.append 'text'
      .text (d) ->
        switch d.type
          when 'resource' then d.id
          when 'content' then 'CONTENT'
          when 'span' then "< >"
          when 'about_resource' then "(#{d.id})"
      .attr
        class: 'label'
        dy: '0.35em'

    ### cola layout ###
    graph.nodes.forEach (v, i) ->
      v.width = PAD_MULTIPLIER*R
      v.height = PAD_MULTIPLIER*R

      # useful to untangle the graph
      v.x = i
      v.y = i

    content = _.find graph.nodes, (d) -> d.type is 'content'
    content.x = R + 20
    content.y = @height/2
    content.fixed = true

    d3cola = cola.d3adaptor()
      .size([@width, @height])
      .linkDistance(60)
      .constraints(graph.constraints)
      .avoidOverlaps(true)
      .nodes(graph.nodes)
      .links(graph.links)
      .on 'tick', () ->
        ### update nodes and links  ###
        nodes
          .attr('transform', (d) -> "translate(#{d.x},#{d.y})")

        links.filter (d) -> not d.inverted
          .attr('x1', (d) -> d.source.x)
          .attr('y1', (d) -> d.source.y)
          .attr('x2', (d) -> d.target.x)
          .attr('y2', (d) -> d.target.y)

        links.filter (d) -> d.inverted
          .attr('x1', (d) -> d.target.x)
          .attr('y1', (d) -> d.target.y)
          .attr('x2', (d) -> d.source.x)
          .attr('y2', (d) -> d.source.y)

        link_labels
          .attr
            transform: (d) -> "translate(#{(d.source.x+d.target.x)/2} #{(d.source.y+d.target.y)/2}) rotate(#{ Math.atan2((d.target.y-d.source.y),(d.target.x-d.source.x))/Math.PI/2*360 }) translate(0,-5)"

    enter_nodes
      .call(d3cola.drag)

    d3cola.start(100,30,30)
