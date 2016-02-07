Editor = Backbone.D3View.extend
  initialize: () ->
    @d3el.classed 'Editor', true

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
      value: @model.attributes.code
    }

    # create the toolbar buttons
    bar.append 'button'
      .text '< >'
      .on 'click', () =>
        editor.replaceSelection '<' + editor.getSelection() + '>' # FIXME support more than one selection
        editor.focus()
      .style
        color: '#1f77b4'
      .attr
        title: 'Insert a new span, or transform the selected text into a span.'

    bar.append 'button'
      .text '( )'
      .on 'click', () =>
        editor.replaceSelection '()' # FIXME support more than one selection
        pos = editor.getCursor()
        pos.ch -= 1
        editor.setCursor pos
        editor.focus()
      .style
        color: '#ff7f0e'
      .attr
        title: 'Insert a new about reference. Use it after a span or in a triple subject.'

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

      # TODO debounce this
      @model.save()

    # write the code into the editor when is loaded from the server
    @listenTo @model, 'sync', () =>
      editor.setValue @model.attributes.code # this also fires the above 'change' callback

    # react to parse events to do the syntax highlighting
    @listenTo @model, 'parse_span', (span) ->
      editor.markText {line: span.code_line, ch: span.code_start}, {line: span.code_line, ch: span.code_start+1}, {className: 'angle_bracket code'}
      editor.markText {line: span.code_line, ch: span.code_start+span.content.length+1}, {line: span.code_line, ch: span.code_start+span.content.length+2}, {className: 'angle_bracket code'}

      editor.markText {line: span.code_line, ch: span.code_start}, {line: span.code_line, ch: span.code_start+span.content.length+2}, {className: 'span'}

    @listenTo @model, 'parse_about', (about) ->
      editor.markText {line: about.code_line, ch: about.code_end-1}, {line: about.code_line, ch: about.code_end}, {className: 'round_bracket code'}
      editor.markText {line: about.code_line, ch: about.code_end-about.id.length-2}, {line: about.code_line, ch: about.code_end}, {className: 'round_bracket code'}

    @listenTo @model, 'parse_directive', (directive) ->
      editor.addLineClass directive.code_line, 'background', 'directive'
      editor.addLineClass directive.code_line, 'text', 'directive code'

    @listenTo @model, 'parse_directive_block_opener', (opener) ->
      editor.addLineClass opener.code_line, 'background', 'directive_block_opener'
      editor.addLineClass opener.code_line, 'text', 'directive_block_opener code'

    @listenTo @model, 'parse_directive_block_closer', (closer) ->
      editor.addLineClass closer.code_line, 'background', 'directive_block_closer'
      editor.addLineClass closer.code_line, 'text', 'directive_block_closer code'

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
