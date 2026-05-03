# jekyll-llms

Generate LLM-friendly files for Jekyll sites.

## Installation

Add the gem to your Jekyll site:

```ruby
group :jekyll_plugins do
  gem "jekyll-llms"
end
```

Enable the plugin in `_config.yml`:

```yaml
plugins:
  - jekyll-llms

llms:
  markdown: true
  llms_txt: true
  include:
    - pages
    - posts
  exclude:
    - /404.html
    - /assets/**
```

Use front matter to exclude a page or document:

```yaml
llms: false
```

## What It Generates

- `llms.txt`: a Markdown index of included pages and posts.
- `.md` sidecars: source-content mirrors for included pages and posts.

The plugin does not convert HTML to Markdown. It removes front matter, renders Liquid in the source body, and writes the result as-is.
