# TEA
Teach the machines how to understand and analyze texts!

TEA stands for Text Encoder and Annotator. By using TEA, you can enrich digital representations of textual documents by using a Markdown-inspired language.

# The language
The TEA language lets you define sections of interest, called *spans*, by surrounding text with angle brackets (`<`, `>`). Spans can be linked to an RDF resource representing a named entity, a lexical entry, or whatever by following it with round brackets containing a local identifier:

```
<Bob>(b) is a good guy. <He>(b) is friend with <Alice>(a).
```

Then it makes possible to add RDF triples describing the resources within special code blocks delimited by lines with `+++`:

```
<Bob>(b) is a good guy. <He>(b) is friend with <Alice>(a).
+++
(a) rdf:type foaf:Person
(b) rdf:type foaf:Person
(a) foaf:knows (b)
+++
```

## Contribute to TEA

### Configure grunt
```
npm install grunt
npm install grunt-contrib-coffee
npm install grunt-contrib-watch
npm install grunt-contrib-concat
```
