Editor = Backbone.D3View.extend
  initialize: () ->
    @d3el.classed 'Editor', true
    @save = _.throttle (() => @model.save()), 10000, true

    bar = @d3el.append 'div'
      .attr
        class: 'bar'

    # Chrome bug workaround (https://github.com/codemirror/CodeMirror/issues/3679)
    editor_div = @d3el.append 'div'
      .attr
        class: 'editor_div'
      .style
        position: 'relative'

    wrapper = editor_div.append 'div'
      .style
        position: 'absolute'
        height: '100%'
        width: '100%'

    # create the CodeMirror editor
    editor = CodeMirror wrapper.node(), {
      lineNumbers: false,
      gutters: ['error_gutter'],
      value: @model.attributes.code,
      readOnly: 'nocursor'
    }

    # create the toolbar buttons
    bar.append 'button'
      .text 'Edit'
      .on 'click', () =>
        editor.setOption('readOnly', false)
        editor.focus()
        d3.selectAll 'button'
          .attr
            disabled: null
      .style
        color: '#555'
      .attr
        title: 'Start editing the document.'

    bar.append 'button'
      .text 'Undo'
      .on 'click', () =>
        editor.execCommand('undo')
        editor.focus()
      .style
        color: '#555'
      .attr
        title: 'Cancel the last change.'
        disabled: true

    bar.append 'button'
      .text 'Redo'
      .on 'click', () =>
        editor.execCommand('redo')
        editor.focus()
      .style
        color: '#555'
      .attr
        title: 'Redo the last change.'
        disabled: true

    bar.append 'button'
      .text '< >'
      .on 'click', () =>
        editor.replaceSelection '<' + editor.getSelection() + '>' # FIXME support more than one selection
        editor.focus()
      .style
        color: '#1f77b4'
      .attr
        title: 'Insert a new span, or transform the selected text into a span.'
        disabled: true

    bar.append 'button'
      .text '( )'
      .on 'click', () =>
        editor.replaceSelection '(id)' # FIXME support more than one selection
        pos = editor.getCursor()
        editor.setSelection {line: pos.line, ch: pos.ch-3}, {line: pos.line, ch:  pos.ch-1}
        editor.focus()
      .style
        color: '#ff7f0e'
      .attr
        title: 'Insert a new about reference.\nUse it after a span or in a triple subject.'
        disabled: true

    bar.append 'button'
      .text '+++'
      .on 'click', () =>
        editor.replaceSelection '+++\n(subj) pred obj\n+++' # FIXME support more than one selection
        pos = editor.getCursor()
        editor.setSelection {line: pos.line-1, ch: 0}, {line: pos.line-1, ch: 15}
        editor.focus()
      .style
        color: '#555'
      .attr
        title: 'Insert a new block for RDF triples.'
        disabled: true

    bar.append 'button'
      .text 'term'
      .on 'click', () =>
        editor.replaceSelection '(subj) its:termInfoRef cll:math/' # FIXME support more than one selection
        pos = editor.getCursor()
        editor.setSelection {line: pos.line, ch: 1}, {line: pos.line, ch: 5}
        editor.focus()
      .style
        color: '#555'
      .attr
        title: 'Insert a new RDF triple with a its:termInfoRef predicate and an HTTP url as object.\nUse it within a +++ block.'
        disabled: true

    bar.append 'button'
      .text 'sameAs'
      .on 'click', () =>
        editor.replaceSelection '(subj) owl:sameAs dbr:' # FIXME support more than one selection
        pos = editor.getCursor()
        editor.setSelection {line: pos.line, ch: 1}, {line: pos.line, ch: 5}
        editor.focus()
      .style
        color: '#555'
      .attr
        title: 'Insert a new RDF triple with a owl:sameAs predicate and a DBPedia resource as object.\nUse it within a +++ block.'
        disabled: true

    bar.append 'button'
      .text 'topicOf'
      .on 'click', () =>
        editor.replaceSelection '(subj) foaf:isPrimaryTopicOf http://' # FIXME support more than one selection
        pos = editor.getCursor()
        editor.setSelection {line: pos.line, ch: 1}, {line: pos.line, ch: 5}
        editor.focus()
      .style
        color: '#555'
      .attr
        title: 'Insert a new RDF triple with a foaf:isPrimaryTopicOf predicate and an HTTP url as object.\nUse it within a +++ block.'
        disabled: true

    bar.append 'button'
      .text 'comment'
      .on 'click', () =>
        editor.replaceSelection '(subj) rdfs:comment ""' # FIXME support more than one selection
        pos = editor.getCursor()
        editor.setSelection {line: pos.line, ch: 1}, {line: pos.line, ch: 5}
        editor.focus()
      .style
        color: '#555'
      .attr
        title: 'Insert a new RDF triple with a rdfs:comment predicate and a string literal as object.\nUse it within a +++ block.'
        disabled: true

    editor.on 'change', () =>
      # clear syntax highlighting
      editor.getAllMarks().forEach (mark) =>
        mark.clear()

      d3.range(editor.firstLine(), editor.lastLine()+1).forEach (l) =>
        editor.removeLineClass l, 'background'
        editor.removeLineClass l, 'text'

      editor.clearGutter 'error_gutter'

      # update the document model
      @model.set
        code: editor.getValue()

      @model.parse()
      @save()

    # write the code into the editor when is loaded from the server
    @listenTo @model, 'sync', () =>
      editor.setValue @model.attributes.code # this also fires the above 'change' callback

    # react to parse events to do the syntax highlighting
    @listenTo @model, 'parse_span', (span) ->
      editor.markText {line: span.code_line, ch: span.code_start}, {line: span.code_line, ch: span.code_start+1}, {className: 'angle_bracket'}
      editor.markText {line: span.code_line, ch: span.code_start+span.content.length+1}, {line: span.code_line, ch: span.code_start+span.content.length+2}, {className: 'angle_bracket'}

      editor.markText {line: span.code_line, ch: span.code_start}, {line: span.code_line, ch: span.code_start+span.content.length+2}, {className: 'span'}

    @listenTo @model, 'parse_about', (about) ->
      editor.markText {line: about.code_line, ch: about.code_start}, {line: about.code_line, ch: about.code_end}, {className: 'about_resource code'}

    @listenTo @model, 'parse_directive', (directive) ->
      editor.addLineClass directive.code_line, 'background', 'directive'
      editor.addLineClass directive.code_line, 'text', 'code directive_block_code'
      editor.markText {line: directive.code_line, ch: directive.code_subject_start}, {line: directive.code_line, ch: directive.code_subject_end}, {className: 'about_resource code'}

    @listenTo @model, 'parse_directive_block_opener', (opener) ->
      editor.addLineClass opener.code_line, 'background', 'directive_block_opener'
      editor.addLineClass opener.code_line, 'text', 'code directive_block_code'

    @listenTo @model, 'parse_directive_block_closer', (closer) ->
      editor.addLineClass closer.code_line, 'background', 'directive_block_closer'
      editor.addLineClass closer.code_line, 'text', 'code directive_block_code'

    @listenTo @model, 'parse_error', (message, details) ->
      error_marker = d3.select document.createElement('a')
        .text 'X'
        .style
          'text-align': 'center'
          background: 'red'
          color: 'white'
          display: 'inline-block'
          width: '10px'
          'margin-left': '1px'
        .attr
          title: "Unexpected #{details.token}"

      editor.setGutterMarker details.line, 'error_gutter', error_marker.node()
      editor.markText {line: details.loc.first_line-1, ch: details.loc.first_column+1}, {line: details.loc.last_line-1, ch: details.loc.last_column+1}, {className: 'error'}
