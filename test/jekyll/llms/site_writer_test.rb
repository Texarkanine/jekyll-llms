# frozen_string_literal: true

require "test_helper"

class JekyllLlmsSiteWriterTest < Minitest::Test
  cover "Jekyll::Llms::SiteWriter"

  def test_writes_index_and_markdown_files
    build_site({}, {
      "_layouts/default.html" => default_layout,
      "page.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Page
        description: Page description.
        ---

        Page body.
      MARKDOWN
    }) do |_site, destination|
      assert_includes read_output(destination, "llms.txt"), "- [Page](https://example.com/base/page.md): Page description."
      assert_equal "Page body.\n", read_output(destination, "page.md")
      assert_includes read_output(destination, "page.html"), %(<link rel="alternate" type="text/markdown" href="https://example.com/base/page.md">)
    end
  end

  def test_can_disable_llms_txt_while_keeping_markdown_files
    build_site({ "llms" => { "markdown" => true, "llms_txt" => false, "include" => ["pages"], "exclude" => [] } }, {
      "_layouts/default.html" => default_layout,
      "page.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Page
        ---

        Page body.
      MARKDOWN
    }) do |_site, destination|
      refute_path_exists output_path(destination, "llms.txt")
      assert_equal "Page body.\n", read_output(destination, "page.md")
      assert_includes read_output(destination, "page.html"), %(<link rel="alternate" type="text/markdown" href="https://example.com/base/page.md">)
    end
  end

  def test_can_disable_markdown_files_while_keeping_original_index_links
    build_site({ "baseurl" => "", "llms" => { "markdown" => false, "llms_txt" => true, "include" => ["pages"], "exclude" => [] } }, {
      "_layouts/default.html" => default_layout,
      "page.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Page
        ---

        Page body.
      MARKDOWN
    }) do |_site, destination|
      assert_includes read_output(destination, "llms.txt"), "- [Page](https://example.com/page)"
      refute_path_exists output_path(destination, "page.md")
      refute_includes read_output(destination, "page.html"), %(type="text/markdown")
    end
  end

  def test_uses_original_links_for_html_sources
    build_site({}, {
      "_layouts/default.html" => default_layout,
      "index.html" => <<~HTML,
        ---
        layout: default
        title: Home
        description: Home page.
        ---

        <h1>Home</h1>
      HTML
    }) do |_site, destination|
      assert_includes read_output(destination, "llms.txt"), "- [Home](https://example.com/base/): Home page."
      refute_path_exists output_path(destination, "index.md")
      refute_includes read_output(destination, "index.html"), %(type="text/markdown")
    end
  end

  def test_excludes_project_docs_by_default
    build_site({ "llms" => :absent }, {
      "_layouts/default.html" => default_layout,
      "README.md" => <<~MARKDOWN,
        ---
        layout: default
        title: README
        description: Should not be published to llms.txt.
        ---

        Secret-adjacent setup notes.
      MARKDOWN
      "CHANGELOG.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Changelog
        description: Release notes should not be published to llms.txt.
        ---

        Internal release notes.
      MARKDOWN
    }) do |_site, destination|
      refute_includes read_output(destination, "llms.txt"), "README"
      refute_includes read_output(destination, "llms.txt"), "Changelog"
      refute_path_exists output_path(destination, "README.md")
      refute_path_exists output_path(destination, "CHANGELOG.md")
    end
  end

  private

  def default_layout
    "<html><head><title>{{ page.title }}</title></head><body>{{ content }}</body></html>\n"
  end
end
