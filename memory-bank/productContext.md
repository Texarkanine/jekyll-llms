# Product Context

## Target Audience

Jekyll site operators who want LLM crawlers and tools to consume a site's content without scraping HTML — typically docs sites, blogs, and personal sites already publishing Markdown-backed pages.

## Use Cases

- Publish a site-wide `llms.txt` index that lists included content with stable URLs.
- Ship Markdown sidecars next to HTML pages so agents can read source bodies instead of rendered markup.
- Point HTML pages at those sidecars via standard alternate links.
- Opt specific pages out, and include or exclude paths / collections without rewriting the site structure.

## Key Benefits

- LLM-friendly artifacts are generated as part of the normal Jekyll build.
- Operators keep using familiar Jekyll concepts (pages, posts, collections, front matter) rather than a parallel content model.
- Defaults stay out of the way: enable what you need, exclude what you don't.

## Success Criteria

- A configured Jekyll site produces the expected `llms.txt` and Markdown sidecars under `site.dest` after a normal build.
- Included / excluded / opted-out content matches operator intent.
- The gem stays small, predictable, and safe to adopt on existing sites.

## Key Constraints

- Must integrate as a Jekyll plugin (hook into the build), not a separate publish pipeline.
- Prefer native Jekyll data (pages, posts, collections) over soft dependencies on third-party archive plugins.
- Quality bar for the gem includes full line coverage and mutation testing (see `AGENTS.md`).
