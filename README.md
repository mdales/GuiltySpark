# Guilty Spark

A very basic search engine for my static website. Consists of a indexer that will run over the markdown+frontmatter pre-rendered documents, and then a small server that will respond to queries with a list of matching documents based on a combination of the corpus saved by the indexer and a bibliography saved by the static site generator.

## Bibliography

It assumes there is a helping hand from the static site builder, in the form of a bibliography JSON file that has an entry for every searchable page, which looks like:

```
{
	"pages": [
		{
  			"title": "Some notes",
  			"link": "/blog/some-notes/",
  			"date": "2022-04-21T09:13:56Z",
  			"synopsis": "A look at stuff.",
  			"thumbnail": {
				"1x": "120x120_fit_box.png",
				"2x": "240x240_fit_box.png"
  			},
  			"tags": [
				"stuff",
				"notes"
  			],
  			"origin": "blog/some-notes/index.md"
		},
		... // rest of pages here.
	]
}
```

The thumbnail and synopsis tags are optional, the other fields are mandatory.
