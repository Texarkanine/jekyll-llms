# frozen_string_literal: true

require "test_helper"

class JekyllLlmsTest < Minitest::Test
  cover "Jekyll::Llms"

  def test_hook_generates_markdown_sidecars_only_for_markdown_sources
    build_site({}, {
      "_layouts/default.html" => <<~HTML,
        <html><head><title>{{ page.title }}</title></head><body>{{ content }}</body></html>
      HTML
      "index.html" => <<~HTML,
        ---
        layout: default
        title: Home
        description: Home page.
        ---

        <h1>{{ site.title }}</h1>
      HTML
      "page.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Page
        description: Page body.
        ---

        Page {{ site.title }}.
      MARKDOWN
    }) do |_site, destination|
      assert_includes read_output(destination, "llms.txt"), "- [Home](https://example.com/base/): Home page."
      assert_includes read_output(destination, "llms.txt"), "- [Page](https://example.com/base/page.md): Page body."
      refute_path_exists output_path(destination, "index.md")
      assert_equal "Page Fixture Site.\n", read_output(destination, "page.md")
      refute_includes read_output(destination, "index.html"), %(type="text/markdown")
      assert_includes read_output(destination, "page.html"), %(<link rel="alternate" type="text/markdown" href="https://example.com/base/page.md">)
    end
  end
end
