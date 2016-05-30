Editor = Backbone.D3View.extend
  namespace: null
  tagName: 'div'

  initialize: (conf) ->
    @d3el.classed 'Editor', true
    @save = _.throttle (() =>
      @model.save(null, {
        success: () =>
          @save_feedback_icon.classed 'hidden', true
        error: () =>
          @save_feedback_icon.classed 'hidden', false
      })

      # index the document
      # FIXME this is temporary - index operations should be done from the server behind the scenes, whenever a document is saved
      triples = []
      @model.attributes.annotations.forEach (s) ->
        triples = triples.concat s.triples.map (t) -> {
          subject: t.subject,
          predicate: t.predicate_uri,
          object: t.object_uri,
          start: s.start,
          end: s.end
        }

      o = {
        id: @model.attributes.index_id,
        idDoc: @model.attributes.index_id,
        code: @model.attributes.code,
        name: @model.attributes.label,
        text: @model.attributes.text,
        triples: triples
      }

      d3.json 'http://wafi.iit.cnr.it:33065/ClaviusWeb-1.0.3/ClaviusGraph/update'
        .post JSON.stringify(o), (error, d) => # FIXME passing the body as a string seems strange
          throw error if error
      ), 5000, true

    # create the toolbar
    bar = @d3el.append 'div'
      .attr
        class: 'bar'

    bar.append 'button'
      .text 'Undo'
      .on 'click', () =>
        @editor.execCommand('undo')
        @editor.focus()
        @update()
      .style
        color: '#555'
      .attr
        title: 'Cancel the last change.'

    bar.append 'button'
      .text 'Redo'
      .on 'click', () =>
        @editor.execCommand('redo')
        @editor.focus()
        @update()
      .style
        color: '#555'
      .attr
        title: 'Redo the last change.'

    bar.append 'button'
      .text '/* */'
      .on 'click', () =>
        @editor.replaceSelection '/* comment */' # FIXME support more than one selection
        pos = @editor.getCursor()
        @editor.focus()
        @update()
        @editor.setSelection {line: pos.line, ch: 3}, {line: pos.line, ch: 10}
      .style
        color: '#449444'
      .attr
        title: 'COMMENT\nInsert a new comment block.\nThe content of a comment block is not intepreted as text nor as annotations.'

    bar.append 'button'
      .text '---'
      .on 'click', () =>
        @editor.replaceSelection '--- id' # FIXME support more than one selection
        pos = @editor.getCursor()
        @editor.focus()
        @update()
        @editor.setSelection {line: pos.line, ch: 4}, {line: pos.line, ch: 6}
      .style
        color: 'rgb(183, 58, 58)'
      .attr
        title: 'BREAK\nInsert a symbol marking the beginning of a new section of text (e.g, a page).\nA break can be given an ID to be used in RDF triples, to annotate the corresponding text section.'

    bar.append 'button'
      .text '{ }'
      .on 'click', () =>
        selection = @editor.getSelection()
        sels = @editor.listSelections() # FIXME support more than one selection

        @editor.replaceSelection '{' + selection + '}' # FIXME support more than one selection

        @editor.focus()
        @update()
      .style
        color: 'rgb(183, 58, 58)'
      .attr
        title: 'AUTHOR\'S ADDITION\nInsert a new author\'s addition, or mark the selected text as an author\'s addition.'

    bar.append 'button'
      .text '[ ]'
      .on 'click', () =>
        selection = @editor.getSelection()
        sels = @editor.listSelections() # FIXME support more than one selection

        @editor.replaceSelection '[' + selection + ']' # FIXME support more than one selection

        @editor.focus()
        @update()
      .style
        color: 'rgb(183, 58, 58)'
      .attr
        title: 'EDITOR\'S ADDITION\nInsert a new editor\'s addition, or mark the selected text as an editor\'s addition.'

    bar.append 'button'
      .text '<< >>'
      .on 'click', () =>
        selection = @editor.getSelection()
        sels = @editor.listSelections() # FIXME support more than one selection

        @editor.replaceSelection '<id<' + selection + '>id>' # FIXME support more than one selection

        if sels[0].anchor.line < sels[0].head.line or sels[0].anchor.line == sels[0].head.line and sels[0].anchor.ch < sels[0].head.ch
          start = sels[0].anchor
          end = sels[0].head
        else
          start = sels[0].head
          end = sels[0].anchor

        end_offset = if start.line is end.line then 4 else 0

        @editor.focus()
        @update()
        @editor.setSelections [
          {anchor: {line: start.line, ch: start.ch+1}, head: {line: start.line, ch:  start.ch+3}},
          {anchor: {line: end.line, ch: end.ch+1+end_offset}, head: {line: end.line, ch:  end.ch+3+end_offset}}
        ]
      .style
        color: '#1f77b4'
      .attr
        title: 'SPAN\nInsert a new span, or transform the selected text into a span.\nA span can be given an ID to be used in RDF triples, to annotate the corresponding text portion.'

    bar.append 'button'
      .text '+++'
      .on 'click', () =>
        @editor.replaceSelection '+++\nsubj pred obj\n+++' # FIXME support more than one selection
        pos = @editor.getCursor()
        @editor.focus()
        @update()
        @editor.setSelection {line: pos.line-1, ch: 0}, {line: pos.line-1, ch: 15}
      .style
        color: '#555'
      .attr
        title: 'RDF TRIPLES BLOCK\nInsert a new block for RDF triples.'

    # Dropdown button
    dropdown = bar.append 'span'
      .attr
        class: 'dropdown_button'

    dropdown_buttons = dropdown.append 'div'
    dropdown_buttons.append 'button'
      .text 'triple'
      .on 'click', () =>
        @editor.replaceSelection "subj pred obj" # FIXME support more than one selection
        pos = @editor.getCursor()
        @editor.focus()
        @update()
        @editor.setSelection {line: pos.line, ch: 0}, {line: pos.line, ch: 4}
      .style
        color: '#555'
      .attr
        title: 'RDF TRIPLE\nInsert a new RDF triple.\nUse it within a +++ block.'
    dropdown_buttons.append 'button'
      .html '&blacktriangledown;'
      .on 'click', () =>
        if d3.select('.Editor .dropdown_button .items').style('display') is 'none' then d3.select('.Editor .dropdown_button .items').style('display', 'inline') else d3.select('.Editor .dropdown_button .items').style('display', 'none')
      .style
        color: '#555'

    predicates = {
      is: 'its:taIdentRef',
      type: 'its:taClassRef',
      page: 'foaf:page',
      comment: 'rdfs:comment'
    }

    items = dropdown.append 'div'
      .attr
        class: 'items'
      .selectAll '.item'
        .data Object.keys(predicates)
    items.enter().append 'div'
      .attr
        class: 'item'
      .text (d) -> d
      .on 'click', (d) =>
        @editor.replaceSelection "subj #{d} obj" # FIXME support more than one selection
        pos = @editor.getCursor()
        @editor.focus()
        @update()
        @editor.setSelection {line: pos.line, ch: 0}, {line: pos.line, ch: 4}

        d3.select('.Editor .dropdown_button .items').style('display', 'none')

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
        {regex: new RegExp('^\\+\\+\\+$'), token: 'triple_section_open', next: 'triple_section'},
        {regex: new RegExp('\\[\.\.\.\\]'), token: 'gap'},
        {regex: new RegExp('\\[…\\]'), token: 'gap'},
        {regex: new RegExp('\\['), token: 'editor_addition_delimiter'},
        {regex: new RegExp('\\]'), token: 'editor_addition_delimiter'},
        {regex: new RegExp('\\{'), token: 'author_addition_delimiter'},
        {regex: new RegExp('\\}'), token: 'author_addition_delimiter'},
        {regex: new RegExp('^(---)(.*)'), token: ['break','break_id']}
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

    @editor.on 'keyup', (_.throttle (() => @update()), 200, true) # need to be sure to read the new character
    @editor.on 'drop', () => @update()

    # write the code into the editor when is loaded from the server for the first time
    @listenTo @model, 'sync', () =>
      if @model.previous('code') is null
        @editor.setValue @model.attributes.code
        @update()

  update: () ->
    @compile()

    @model.set 'code', @editor.getValue()
    @save()

  render: () ->
    @editor.refresh()

  compile: () ->
    @status_bar.text 'All ok.'
    @status_bar.classed 'error', false

    # clear highlighting
    @editor.getAllMarks().forEach (mark) ->
      mark.clear()

    @section_highlight()

    try
      data = @parser.parse @editor.getValue()
      @spans_highlight(data.spans)
      @model.set
        annotations: data.spans
        text: data.plain_text
    catch e
      @status_bar.text "Line #{e.location.start.line}: #{e.message}"
      @status_bar.classed 'error', true

  spans_highlight: (spans) ->
    spans.forEach (s) =>
      @editor.markText {line: s.start_code_location.start.line-1, ch: s.start_code_location.start.column-1}, {line: s.end_code_location.end.line-1, ch: s.end_code_location.end.column-1}, {className: 'span'}

  section_highlight: () ->
    section_type = null
    line_number = 0

    @editor.eachLine (l) =>
      @editor.removeLineClass line_number, 'background'
      @editor.removeLineClass line_number, 'text'

      if section_type?
        @editor.addLineClass line_number, 'background', "#{section_type}_section"
        @editor.addLineClass line_number, 'text', "#{section_type}_section_text"

      # triples section close
      if l.text is '+++' and section_type is 'triples'
        @editor.addLineClass line_number, 'background', "#{section_type}_section_close"
        section_type = null
      # triples section open
      else if l.text is '+++' and not section_type?
        section_type = 'triples'
        @editor.addLineClass line_number, 'background', "#{section_type}_section_open"
        @editor.addLineClass line_number, 'text', "#{section_type}_section_text"

      # comments section open
      if l.text[0...2] is '/*' and not section_type?
        section_type = 'comments'
        @editor.addLineClass line_number, 'background', "#{section_type}_section_open"
        @editor.addLineClass line_number, 'text', "#{section_type}_section_text"
      # comments section close
      if l.text[l.text.length-2...l.text.length] is '*/' and section_type is 'comments'
        @editor.addLineClass line_number, 'background', "#{section_type}_section_close"
        section_type = null

      # break section
      if l.text[0...3] is '---' and not section_type?
        @editor.addLineClass line_number, 'background', "break_section"
        @editor.addLineClass line_number, 'text', "break_section_text"

      line_number++

      return false
