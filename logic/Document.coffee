Document = Backbone.Model.extend
  defaults:
    code: ''
    graph: null

  initialize: () ->
    language = '''
      %lex
      %%

      \\n\\+\\+\\+                             return '/+++'
      \\"                                      return '"'
      "<"                                      return '<'
      ">"                                      return '>'
      "("                                      return '('
      ")"                                      return ')'
      "["                                      return '['
      "]"                                      return ']'
      [_]                                      return 'UNDERSCORE'
      (" "|\\t)+                               return 'SPACES'
      ";"                                      return ';'
      [0-9]                                    return 'DIGIT'
      [a-zA-Z]                                 return 'ALPHABETIC_ASCII'
      .                                        return 'OTHER_CHAR'
      \\n                                      return 'NEWLINE'
      <<EOF>>                                  return 'EOF'

      /lex

      %start Document
      %%

      Document
        : EOF
        | Code EOF
        | CodeDirectiveBlocks EOF
        | CodeDirectiveBlocks NEWLINE Code EOF
        ;

      CodeDirectiveBlocks
        : CodeDirectiveBlock
        | CodeDirectiveBlocks NEWLINE CodeDirectiveBlock
        ;

      CodeDirectiveBlock
        : Code DirectiveBlockOpener NEWLINE Directives DirectiveBlockCloser
        | Code DirectiveBlockOpener DirectiveBlockCloser
        ;

      DirectiveBlockOpener
        : '/+++'
          { yy.new_directive_block_opener(); }
        ;

      DirectiveBlockCloser
        : '/+++'
          { yy.new_directive_block_closer(); }
        ;

      Code
        : TChars
        | Annotation
        | %empty
        | Code Code
        ;

      TChar
        : OTHER_CHAR
        | '"'
        | '('
        | ')'
        | '['
        | ']'
        | ';'
        | UNDERSCORE
        | DIGIT
        | ALPHABETIC_ASCII
        | SPACES
        | NEWLINE
        ;

      TChars
        : TChar
          { yy.new_text($1); }
        | TChars TChar
          { $$ = $1+$2; yy.new_text($2);}
        ;

      Annotation
        : '<' TChars '>'
          { yy.new_span($2, $1+$2+$3); }
        | '<' TChars '>' '(' Id ')'
          { span = yy.new_span($2, $1+$2+$3); yy.new_about(span, $5, $4+$5+$6); }
        ;

      TextWithoutNewlineNorSpaceChar
        : NotNewlineNorSpaceChar
        | TextWithoutNewlineNorSpaceChar NotNewlineNorSpaceChar
          { $$ = $1+$2; }
        ;

      TextWithoutNewline
        : NotNewlineChar
        | TextWithoutNewline NotNewlineChar
          { $$ = $1+$2; }
        ;

      NotNewlineNorSpaceChar
        : OTHER_CHAR
        | '"'
        | '<'
        | '>'
        | '('
        | ')'
        | '['
        | ']'
        | ';'
        | UNDERSCORE
        | DIGIT
        | ALPHABETIC_ASCII
        ;

      NotNewlineChar
        : NotNewlineNorSpaceChar
        | SPACES
        ;

      SpacesOrNothing
        : SPACES
        | %empty
        ;

      SpacesNewlinesOrNothing
        : SPACES
        | %empty
        | SpacesNewlinesOrNothing NEWLINE SpacesNewlinesOrNothing
        ;

      Id
        : IdChar
        | Id IdChar
          { $$ = $1+$2; }
        ;

      IdChar
        : UNDERSCORE
        | DIGIT
        | ALPHABETIC_ASCII
        ;

      Directives
        : Directive
        | Directive NEWLINE Directives
        ;

      Directive
        : SpacesOrNothing '(' Id ')' SpacesOrNothing POSequence SpacesOrNothing
          { yy.new_directive($6, $3); }
        | SpacesOrNothing '[' Id ']' SpacesOrNothing POSequence SpacesOrNothing
          { yy.new_directive($6, $3); }
        | SpacesOrNothing '(' Id ')'
          { yy.new_directive([], $3); }
        | SpacesOrNothing '[' Id ']'
          { yy.new_directive([], $3); }
        | SpacesOrNothing
        ;

      /* RDF */
      POSequence
        : POPair
          { $$ = [$1]; }
        | POSequence SpacesOrNothing ';' SpacesOrNothing POPair
          { $$ = $1.concat([$5]); }
        ;

      POPair
        : Predicate SPACES Object
          { $$ = {predicate: $1, object: $3}; }
        ;

      POChar
        : OTHER_CHAR
        | '<'
        | '>'
        | '('
        | ')'
        | '['
        | ']'
        | UNDERSCORE
        | DIGIT
        | ALPHABETIC_ASCII
        ;

      POChars
        : POChar
        | POChar POChars
          { $$ = $1+$2; }
        ;

      Predicate
        : POChars
        ;

      Object
        : POChars
        | '"' LiteralChars '"'
          { $$ = $1+$2+$3; }
        | '"' '"'
          { $$ = $1+$2; }
        ;

      LiteralChar
        : OTHER_CHAR
        | '<'
        | '>'
        | '('
        | ')'
        | '['
        | ']'
        | UNDERSCORE
        | DIGIT
        | ALPHABETIC_ASCII
        | SPACES
        ;

      LiteralChars
        : LiteralChar
        | LiteralChars LiteralChar
          { $$ = $1+$2; }
        ;

      '''

    # generate the parser on the fly
    Jison.print = () ->
    @_jison_parser = Jison.Generator(bnf.parse(language), {type: 'lalr'}).createParser()

    # custom error handling: trigger an 'error' event
    @_jison_parser.yy.parseError = (message, details) =>
      @trigger('parse_error', message, details)

    # update the parser's status whenever a language item is encountered
    @_jison_parser.yy.new_text = (content) =>
      if content is '\n'
        @code_line += 1
        @code_offset = 0
      else
        @code_offset += content.length

      @offset += content.length
      @plain_text += content

    @_jison_parser.yy.new_span = (content, code) =>
      @code_offset += code.length - content.length

      span = {
        type: 'span',
        start: @offset - content.length,
        end: @offset,
        code_start: @code_offset - code.length,
        code_end: @code_offset,
        code_line: @code_line,
        content: content
      }
      @spans.push span

      @trigger('parse_span', span)

      return span

    @_jison_parser.yy.new_about = (span, id, code) =>
      @code_offset += code.length

      about = {
        id: id,
        type: 'annotation',
        span: span,
        code_start: @code_offset - code.length,
        code_end: @code_offset,
        code_line: @code_line
      }
      @abouts.push about

      # reverse pointer from span to about
      span.about = about

      @trigger('parse_about', about)

      return about

    @_jison_parser.yy.new_directive_block_opener = () =>
      @code_line += 1
      @code_offset = 0
      @trigger('parse_directive_block_opener', {code_line: @code_line})

    @_jison_parser.yy.new_directive_block_closer = () =>
      @code_line += 2
      @code_offset = 0
      @trigger('parse_directive_block_closer', {code_line: @code_line-1})

    @_jison_parser.yy.new_directive = (popairs, id) =>
      @code_line += 1
      @code_offset = 0

      directive = {
        id: id,
        code_line: @code_line,
        code_subject_start: 0,
        code_subject_end: "#{id}".length+2,
        popairs: popairs
      }
      @directives.push directive

      @trigger('parse_directive', directive)

      return directive

  parse: () ->
    # parse the code
    @offset = 0
    @code_line = 0
    @code_offset = 0
    @spans = []
    @abouts = []
    @directives = []
    @plain_text = ''

    try
      @_jison_parser.parse(@attributes.code)

      # resolve about-directive reference
      @abouts.forEach (a) =>
        a.directives = []
        @directives.forEach (d) =>
          if a.id is d.id
            a.directives.push d

      # update the graph
      content = {type: 'content'}
      nodes = [content]
      links = []
      graph = {nodes: nodes, links: links}
      span_index = {}
      about_resource_index = {}

      @directives.forEach (d) ->
        if d.id not of about_resource_index
          n = {type: 'about_resource', id: d.id}
          nodes.push n
          about_resource_index[d.id] = n
        else
          n = about_resource_index[d.id]

        d.popairs.forEach (p) ->
          ext_n = {type: 'resource', id: p.object}
          nodes.push ext_n

          links.push {source: n, target: ext_n, type: 'predicate', predicate: p.predicate}

      @spans.forEach (s, i) ->
        s.id = i # FIXME spans have no meaningful id

        n = {type: 'span', id: s.id}
        nodes.push n
        span_index[s.id] = n

        links.push {source: content, target: n, start: s.start, end: s.end, type: 'locus', inverted: true}

      @abouts.forEach (a, i) ->
        # create about nodes with id and no directive associated
        if a.id? and a.directives.length is 0 and a.id not of about_resource_index
          n = {type: 'about_resource', id: a.id}
          nodes.push n
          about_resource_index[a.id] = n

        links.push {source: span_index[a.span.id], target: about_resource_index[a.id], type: 'about'}

      @set
        graph: graph
    catch error
      console.debug error

  sync: (method, model, options) ->
    switch method
      when 'read'
        return d3.json 'http://wafi.iit.cnr.it:33065/ClaviusWeb-1.0.1/ClaviusGraph/load'
          # .header('Content-Type', 'application/json') FIXME server does not accept this
          .post JSON.stringify({id: model.attributes.id}), (error, d) => # FIXME passing the body as a string seems strange
            throw error if error

            # ignore all the other fields
            @set
              code: d.code

            @trigger 'sync'
      when 'update'
        return d3.json 'http://wafi.iit.cnr.it:33065/ClaviusWeb-1.0.1/ClaviusGraph/update'
          # .header('Content-Type', 'application/json') FIXME server does not accept this
          .post JSON.stringify({id: model.attributes.id, code: model.attributes.code, name: model.attributes.name}), (error, d) => # FIXME passing the body as a string seems strange
            throw error if error

            # ignore all the other fields
            @set
              code: d.code

            # @trigger 'sync' FIXME this causes an infinite loop
