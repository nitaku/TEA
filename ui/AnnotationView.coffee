AnnotationView = Backbone.D3View.extend
  namespace: null
  tagName: 'div'

  initialize: () ->
    @d3el
      .attr
        class: 'AnnotationView'
    @listenTo @model, 'change:annotations', @render

  render: () ->
    annotations_data = @model.get 'annotations'

    annotations = @d3el.selectAll '.annotation'
      .data annotations_data

    annotations.enter().append 'table'
      .attr
        class: 'annotation'

    annotations
      .html (d) ->
        rowspan = Math.max 1, d.triples.length
        triples = ''
        d.triples.forEach (t,i) ->
          if i > 0
            triples += '</tr><tr>'
          object = if t.object_type is 'uri' then "<a href='#{t.object_uri}'>#{t.object}</a>" else '"'+t.object+'"'
          triples += "<td class='predicate'><a href='#{t.predicate_uri}'>#{t.predicate}</a></td><td class='object #{t.object_type}'>#{object}</td>"
        # hide automatic IDs
        id = if d.id[0] is '_' then '' else d.id
        return "<tr><td class='id' rowspan='#{rowspan}'>#{id}</td><td rowspan='#{rowspan}' class='#{d.type}'>#{d.text.replace(/\n/g,'↵')}</td>#{triples}</tr>"

    annotations.exit()
      .remove()
