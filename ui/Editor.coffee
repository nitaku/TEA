Editor = Backbone.D3View.extend
  namespace: null
  tagName: 'div'

  events:
    input: 'compile'

  initialize: (conf) ->
    @d3el.classed 'Editor', true
    @save = _.throttle (() =>
      @model.save(null, {
        success: () =>
          @save_feedback_icon.classed 'hidden', true
        error: () =>
          @save_feedback_icon.classed 'hidden', false
      })), 5000, true

    # create the toolbar
    bar = @d3el.append 'div'
      .attr
        class: 'bar'

    bar.append 'button'
      .text 'Undo'
      .on 'click', () =>
        @editor.execCommand('undo')
        @editor.focus()
      .style
        color: '#555'
      .attr
        title: 'Cancel the last change.'

    bar.append 'button'
      .text 'Redo'
      .on 'click', () =>
        @editor.execCommand('redo')
        @editor.focus()
      .style
        color: '#555'
      .attr
        title: 'Redo the last change.'

    bar.append 'button'
      .text '<< >>'
      .on 'click', () =>
        selection = @editor.getSelection()
        @editor.replaceSelection '<id<' + selection + '>id>' # FIXME support more than one selection
        pos = @editor.getCursor()

        @editor.setSelections [{anchor: {line: pos.line, ch: pos.ch-3}, head: {line: pos.line, ch:  pos.ch-1}}, {anchor: {line: pos.line, ch: pos.ch-selection.length-7}, head: {line: pos.line, ch:  pos.ch-selection.length-5}}]
        @editor.focus()
      .style
        color: '#1f77b4'
      .attr
        title: 'Insert a new span, or transform the selected text into a span.'

    bar.append 'button'
      .text '+++'
      .on 'click', () =>
        @editor.replaceSelection '+++\nsubj pred obj\n+++' # FIXME support more than one selection
        pos = @editor.getCursor()
        @editor.setSelection {line: pos.line-1, ch: 0}, {line: pos.line-1, ch: 15}
        @editor.focus()
      .style
        color: '#555'
      .attr
        title: 'Insert a new block for RDF triples.'

    bar.append 'button'
      .text 'triple'
      .on 'click', () =>
        @editor.replaceSelection 'subj pred obj' # FIXME support more than one selection
        pos = @editor.getCursor()
        @editor.setSelection {line: pos.line, ch: 1}, {line: pos.line, ch: 5}
        @editor.focus()
      .style
        color: '#555'
      .attr
        title: 'Insert a new RDF triple.\nUse it within a +++ block.'

    bar.append 'div'
      .attr
        class: 'spacer'

    @save_feedback_icon = bar.append 'div'
      .text "Error saving document!"
      .attr
        class: 'save_feedback_icon hidden'

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

    @status_bar = @d3el.append 'div'
      .attr
        class: 'status_bar'

    @parser = PEG.buildParser conf.breakdown_grammar

    # CodeMirror editor creation
    CodeMirror.defineSimpleMode('hl', {
      start: [
        {regex: new RegExp('<[a-zA-Z0-9][_a-zA-Z0-9]*<'), token: 'span_open'},
        {regex: new RegExp('<<'), token: 'span_open'},
        {regex: new RegExp('>[a-zA-Z0-9][_a-zA-Z0-9]*>'), token: 'span_close'},
        {regex: new RegExp('>>'), token: 'span_close'},
        {regex: new RegExp('^\\+\\+\\+$'), token: 'triple_section_open', next: 'triple_section'}
      ],
      triple_section: [
        {regex: new RegExp('^\\+\\+\\+$'), token: 'triple_section_close', next: 'start'},
        {regex: new RegExp('(^[^ \t]*)([ \t]+)([^ \t]*)([ \t]+)(".*"$)'), token: ['subject', '', 'predicate', '', 'literal']},
        {regex: new RegExp('(^[^ \t]*)([ \t]+)([^ \t]*)([ \t]+)([^" \t]*$)'), token: ['subject', '', 'predicate', '', 'object']}
      ]
    })

    @editor = CodeMirror wrapper.node(), {
      lineWrapping: true
    }

    # FIXME on dragend is also needed
    @editor.on 'keyup', () =>
      @compile()

      @model.set 'code', @editor.getValue()
      @save()

    # write the code into the editor when is loaded from the server for the first time
    @listenTo @model, 'sync', () =>
      if @model.previous('code') is null
        @editor.setValue @model.attributes.code

  render: () ->
    @editor.refresh()

  compile: () ->
    @status_bar.text 'All ok.'
    @status_bar.classed 'error', false

    # clear highlighting
    @editor.getAllMarks().forEach (mark) ->
      mark.clear()

    @triple_section_highlight()

    try
      data = @parser.parse @editor.getValue()
      @spans_highlight(data.spans)
      @model.set 'annotations', data.spans
    catch e
      @status_bar.text "Line #{e.location.start.line}: #{e.message}"
      @status_bar.classed 'error', true

  spans_highlight: (spans) ->
    spans.forEach (s) =>
      @editor.markText {line: s.start_code_location.start.line-1, ch: s.start_code_location.start.column-1}, {line: s.end_code_location.end.line-1, ch: s.end_code_location.end.column-1}, {className: 'span'}

  triple_section_highlight: () ->
    in_section = false
    line_number = 0

    @editor.eachLine (l) =>
      @editor.removeLineClass line_number, 'background'
      @editor.removeLineClass line_number, 'text'

      if in_section
        @editor.addLineClass line_number, 'background', 'triple_section'
        @editor.addLineClass line_number, 'text', 'triple_section_text'

      # triple section open
      if l.text is '+++' and in_section
        in_section = not in_section
        @editor.addLineClass line_number, 'background', 'triple_section_close'
      # triple section close
      else if l.text is '+++'
        in_section = not in_section
        @editor.addLineClass line_number, 'background', 'triple_section_open'

      line_number++

      return false
