# TEA
Teach the machines how to understand and analyze texts!

TEA stands for Text Encoder and Annotator. By using TEA, you can enrich digital representations of textual documents by using a Markdown-inspired language.

# The language
## Spans
The TEA language lets you define sections of interest, called *spans*, by surrounding text with double angle brackets:

```
<<Bob>> is a good guy. <<He>> is friend with <<Alice>>.
```

Spans can be given an alphanumeric string as an identifier:

```
<b<Bob>b> is a good guy. <b<He>b> is friend with <al<Alice>al>.
```

In most cases, the first identifier can be omitted:

```
<<Bob>b> is a good guy. <<He>b> is friend with <<Alice>al>.
```

In the special case of non-hierarchical overlap though, both identifiers are needed:

```
This is a case of <1<non-<2<hierarchical>1> overlap>2>.
```

In the above example, the first span, identified as `1`, contains the text `non-hierarchical`, while the second one (`2`) contains `hierarchical overlap`.

## RDF triples
When spans are defined, it is then possible to add RDF triples describing the selected portions of text by creating a special code block, delimited by lines with `+++`:

```
<<Bob>b> is a good guy. <<He>b> is friend with <<Alice>al>.
+++
al rdf:type foaf:Person
b rdf:type foaf:Person
al foaf:knows b
+++
```
[FIXME: change the example to use real predicates - rdf:type can't be used like that]
[FIXME: these are not real triples - they are more like triple templates]

## Contribute to TEA

### Configure grunt
```
npm install grunt
npm install grunt-contrib-coffee
npm install grunt-contrib-watch
npm install grunt-contrib-concat
```
