# jekyll-llms

Jekyll plugin that produces LLM-friendly formats alongside a regular website.

Namely: `llms.txt`, optional `llms-full.txt` and scoped indexes, Markdown sidecars, and HTML alternate links to sidecars.

## Installation

Add to `Gemfile` and run `bundle install`
```ruby
group :jekyll_plugins do
  gem "jekyll-llms"
end
```

Add to `_config` file:

```yaml
plugins:
  - jekyll-llms
```


## Output

- `/llms.txt`: Markdown index of included entries.
- `/llms-full.txt`: concatenated Markdown corpus of included entries (optional).
- Per-category and per-collection `llms.txt` / `llms-full.txt` beside those scopes (optional).
- `*.md`: source-body sidecars for included Markdown-source entries.
- HTML `<link rel="alternate" type="text/markdown" href="...">` tags pointing to sidecars.

Sidecars are source bodies, not HTML-to-Markdown conversions. Front matter is removed. Liquid is rendered unless `render_with_liquid: false` is set. HTML-source entries stay linked by their original URLs. HTML-only entries appear in indexes but are omitted from `llms-full.txt`.

## Configuration

```yaml
llms:
  markdown: true
  llms_txt: true
  llms_full: false
  categories: false
  collection_indexes: false
  include:
    - pages
    - posts
  exclude:
    - /README.md
    - /CHANGELOG.md
    - /404.html
    - /assets/**
```

- `markdown`: generate sidecars for Markdown sources, link `llms.txt` to those sidecars, and add HTML alternate links. Default: `true`.
- `llms_txt`: generate `/llms.txt`. Default: `true`.
- `llms_full`: generate `/llms-full.txt` and scoped `llms-full.txt` when category/collection indexes are enabled. Default: `false`.
- `categories`: generate per-category `llms.txt` (and `llms-full.txt` when `llms_full` is true) for each non-empty category after include/exclude filtering. Default: `false`.
- `collection_indexes`: generate per-collection indexes under `/{label}/` for each included writeable collection (not `pages`/`posts`). Default: `false`.
- `include`: `pages`, `posts`, and output collection names. Default: `[pages, posts]`.
- `exclude`: URL, Markdown path, or source path globs. Default: `[/README.md, /CHANGELOG.md]`.

### Category paths

Category files land under the category archive path. When `jekyll-archives` configures `permalinks.category`, that template is used (with `:name` replaced by `Jekyll::Utils.slugify` of the category name). Otherwise the default is `/category/:name/`, matching jekyll-archives' stock category permalink. The gem does not require jekyll-archives. Custom archives `slug_mode` values are not mirrored in v1.

Per-entry opt-out:

```yaml
llms: false
```

## License

MIT. See `LICENSE.txt`.
