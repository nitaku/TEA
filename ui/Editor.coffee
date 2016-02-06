Editor = Backbone.D3View.extend
  initialize: () ->
    @d3el.classed 'Editor', true

    # Chrome bug workaround (https://github.com/codemirror/CodeMirror/issues/3679)
    @d3el
      .style
        position: 'relative'
    wrapper = @d3el.append 'div'
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

    editor.on 'change', () =>
      # clear syntax highlighting
      editor.getAllMarks().forEach (mark) =>
        mark.clear()

      d3.range(editor.firstLine(), editor.lastLine()+1).forEach (l) =>
        editor.removeLineClass l, 'background'
        editor.removeLineClass l, 'text'

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
      editor.markText {line: span.code_line, ch: span.code_start}, {line: span.code_line, ch: span.code_start+1}, {className: 'angle_bracket'}
      editor.markText {line: span.code_line, ch: span.code_start+span.content.length+1}, {line: span.code_line, ch: span.code_start+span.content.length+2}, {className: 'angle_bracket'}

      editor.markText {line: span.code_line, ch: span.code_start}, {line: span.code_line, ch: span.code_start+span.content.length+2}, {className: 'span'}

    @listenTo @model, 'parse_about', (about) ->
      editor.markText {line: about.code_line, ch: about.code_end-1}, {line: about.code_line, ch: about.code_end}, {className: 'round_bracket'}
      editor.markText {line: about.code_line, ch: about.code_end-about.id.length-2}, {line: about.code_line, ch: about.code_end}, {className: 'round_bracket'}

    @listenTo @model, 'parse_directive', (directive) ->
      editor.addLineClass directive.code_line, 'background', 'directive'

    @listenTo @model, 'parse_directive_block_opener', (opener) ->
      editor.addLineClass opener.code_line, 'background', 'directive_block_opener'
      editor.addLineClass opener.code_line, 'text', 'directive_block_opener'

    @listenTo @model, 'parse_directive_block_closer', (closer) ->
      editor.addLineClass closer.code_line, 'background', 'directive_block_closer'
      editor.addLineClass closer.code_line, 'text', 'directive_block_closer'
