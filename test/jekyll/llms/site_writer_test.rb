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

  def test_skips_invalid_markdown_sidecar_without_stopping_other_outputs
    build_site_without_plugin_output({
      "_layouts/default.html" => default_layout,
      "valid.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Valid
        render_with_liquid: false
        ---

        Valid body.
      MARKDOWN
      "invalid.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Invalid
        render_with_liquid: false
        ---

        Invalid body.
      MARKDOWN
    }) do |site, destination|
      File.delete(File.join(File.dirname(destination), "invalid.md"))

      warnings = with_recorded_logs do
        Jekyll::Llms::SiteWriter.new(site).write
      end

      assert_equal "Valid body.\n", read_output(destination, "valid.md")
      refute_path_exists output_path(destination, "invalid.md")
      assert_includes read_output(destination, "valid.html"), %(href="https://example.com/base/valid.md")
      refute_includes read_output(destination, "invalid.html"), %(type="text/markdown")
      assert_includes read_output(destination, "llms.txt"), "- [Valid](https://example.com/base/valid.md)"
      assert_includes read_output(destination, "llms.txt"), "- [Invalid](https://example.com/base/invalid)"
      assert_recorded_warning warnings, "LLMs:", "Skipping markdown sidecar for invalid.md: No such file or directory"
    end
  end

  def test_skips_invalid_liquid_markdown_sidecar_without_stopping_other_outputs
    build_site_without_plugin_output({
      "_layouts/default.html" => default_layout,
      "valid.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Valid
        ---

        Valid body.
      MARKDOWN
      "invalid.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Invalid
        ---

        Initially valid.
      MARKDOWN
    }) do |site, destination|
      write_fixture_file(File.dirname(destination), "invalid.md", <<~MARKDOWN)
        ---
        layout: default
        title: Invalid
        ---

        {% if broken %}
      MARKDOWN

      warnings = with_recorded_logs do
        Jekyll::Llms::SiteWriter.new(site).write
      end

      assert_equal "Valid body.\n", read_output(destination, "valid.md")
      refute_path_exists output_path(destination, "invalid.md")
      assert_recorded_warning warnings, "LLMs:", "Skipping markdown sidecar for invalid.md"
    end
  end

  def test_does_not_skip_destination_write_failures
    build_site_without_plugin_output({
      "_layouts/default.html" => default_layout,
      "page.md" => markdown_page
    }) do |site, destination|
      FileUtils.rm_rf(destination)
      File.write(destination, "not a directory")

      error = assert_raises(Errno::EEXIST) do
        Jekyll::Llms::SiteWriter.new(site).write
      end

      assert_includes error.message, "File exists"
    end
  end

  def test_does_not_log_destination_write_failures_as_skipped_sidecars
    build_site_without_plugin_output({
      "_layouts/default.html" => default_layout,
      "page.md" => markdown_page
    }) do |site, destination|
      FileUtils.rm_rf(destination)
      File.write(destination, "not a directory")

      warnings = with_recorded_logs do
        assert_raises(Errno::EEXIST) do
          Jekyll::Llms::SiteWriter.new(site).write
        end
      end

      assert_empty warnings
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

  def test_writes_root_llms_full_when_enabled
    build_site({
      "llms" => {
        "markdown" => true,
        "llms_txt" => true,
        "llms_full" => true,
        "include" => ["pages"],
        "exclude" => [],
      },
    }, {
      "_layouts/default.html" => default_layout,
      "page.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Page
        ---

        Page body.
      MARKDOWN
    }) do |_site, destination|
      content = read_output(destination, "llms-full.txt")
      assert_includes content, "# Fixture Site"
      assert_includes content, "## Page"
      assert_includes content, "Page body."
    end
  end

  def test_llms_full_uses_default_title_when_site_title_missing
    build_site({
      "title" => :absent,
      "llms" => {
        "markdown" => true,
        "llms_txt" => false,
        "llms_full" => true,
        "include" => ["pages"],
        "exclude" => [],
      },
    }, {
      "_layouts/default.html" => default_layout,
      "page.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Page
        ---

        Page body.
      MARKDOWN
    }) do |_site, destination|
      assert_includes read_output(destination, "llms-full.txt"), "# Jekyll Site"
    end
  end

  def test_llms_full_omits_html_and_failed_markdown_without_stopping
    build_site_without_plugin_output({
      "_layouts/default.html" => default_layout,
      "index.html" => <<~HTML,
        ---
        layout: default
        title: Home
        ---

        <h1>Home</h1>
      HTML
      "valid.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Valid
        render_with_liquid: false
        ---

        Valid body.
      MARKDOWN
      "invalid.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Invalid
        render_with_liquid: false
        ---

        Invalid body.
      MARKDOWN
    }) do |site, destination|
      File.delete(File.join(File.dirname(destination), "invalid.md"))
      site.config["llms"] = {
        "markdown" => false,
        "llms_txt" => false,
        "llms_full" => true,
        "include" => ["pages"],
        "exclude" => [],
      }

      Jekyll::Llms::SiteWriter.new(site).write

      content = read_output(destination, "llms-full.txt")
      assert_includes content, "## Valid"
      assert_includes content, "Valid body."
      refute_includes content, "Home"
      refute_includes content, "Invalid"
    end
  end

  def test_writes_category_indexes_when_enabled
    build_site({
      "llms" => {
        "markdown" => true,
        "llms_txt" => true,
        "llms_full" => true,
        "categories" => true,
        "include" => %w[pages posts],
        "exclude" => [],
      },
    }, {
      "_layouts/default.html" => default_layout,
      "_posts/2024-01-01-fable-post.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Fable Post
        categories: [fable]
        ---

        Fable body.
      MARKDOWN
      "_posts/2024-01-02-other-post.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Other Post
        categories: [other]
        ---

        Other body.
      MARKDOWN
    }) do |_site, destination|
      index = read_output(destination, "category/fable/llms.txt")
      assert_includes index, "# fable"
      assert_includes index, "> Category: fable"
      assert_includes index, "Fable Post"
      refute_includes index, "Other Post"

      full = read_output(destination, "category/fable/llms-full.txt")
      assert_includes full, "# fable"
      assert_includes full, "## Fable Post"
      assert_includes full, "Fable body."
      refute_includes full, "Other Post"
    end
  end

  def test_writes_collection_indexes_when_enabled
    build_site({
      "collections" => { "garden" => { "output" => true } },
      "llms" => {
        "markdown" => true,
        "llms_txt" => true,
        "llms_full" => true,
        "collection_indexes" => true,
        "include" => %w[pages posts garden],
        "exclude" => [],
      },
    }, {
      "_layouts/default.html" => default_layout,
      "_garden/note.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Garden Note
        ---

        Garden body.
      MARKDOWN
      "page.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Page
        ---

        Page body.
      MARKDOWN
    }) do |_site, destination|
      index = read_output(destination, "garden/llms.txt")
      assert_includes index, "# garden"
      assert_includes index, "> Collection: garden"
      assert_includes index, "Garden Note"
      refute_includes index, "[Page]"

      full = read_output(destination, "garden/llms-full.txt")
      assert_includes full, "## Garden Note"
      assert_includes full, "Garden body."
    end
  end

  def test_uses_archives_category_path_for_scoped_indexes
    build_site({
      "jekyll-archives" => { "permalinks" => { "category" => "/topics/:name/" } },
      "llms" => {
        "markdown" => true,
        "llms_txt" => true,
        "categories" => true,
        "include" => %w[posts],
        "exclude" => [],
      },
    }, {
      "_layouts/default.html" => default_layout,
      "_posts/2024-01-01-topic-post.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Topic Post
        categories: [fable]
        ---

        Topic body.
      MARKDOWN
    }) do |_site, destination|
      assert_path_exists output_path(destination, "topics/fable/llms.txt")
      refute_path_exists output_path(destination, "topics/fable/llms-full.txt")
      refute_path_exists output_path(destination, "category/fable/llms.txt")
    end
  end

  def test_does_not_write_new_artifacts_when_flags_false
    build_site({
      "collections" => { "garden" => { "output" => true } },
      "llms" => {
        "markdown" => true,
        "llms_txt" => true,
        "include" => %w[pages posts garden],
        "exclude" => [],
      },
    }, {
      "_layouts/default.html" => default_layout,
      "_posts/2024-01-01-fable-post.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Fable Post
        categories: [fable]
        ---

        Fable body.
      MARKDOWN
      "_garden/note.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Garden Note
        ---

        Garden body.
      MARKDOWN
    }) do |_site, destination|
      refute_path_exists output_path(destination, "llms-full.txt")
      refute_path_exists output_path(destination, "category/fable/llms.txt")
      refute_path_exists output_path(destination, "garden/llms.txt")
    end
  end

  def test_omits_excluded_posts_from_scoped_indexes
    build_site({
      "llms" => {
        "markdown" => true,
        "llms_txt" => true,
        "categories" => true,
        "include" => %w[posts],
        "exclude" => ["/blog/secret"],
      },
    }, {
      "_layouts/default.html" => default_layout,
      "_posts/2024-01-01-public.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Public Post
        categories: [fable]
        ---

        Public body.
      MARKDOWN
      "_posts/2024-01-02-secret.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Secret Post
        categories: [fable]
        permalink: /blog/secret
        ---

        Secret body.
      MARKDOWN
    }) do |_site, destination|
      index = read_output(destination, "category/fable/llms.txt")
      assert_includes index, "Public Post"
      refute_includes index, "Secret Post"
    end
  end

  private

  def default_layout
    "<html><head><title>{{ page.title }}</title></head><body>{{ content }}</body></html>\n"
  end

  def build_site_without_plugin_output(files)
    build_site({ "llms" => { "markdown" => false, "llms_txt" => false, "include" => ["pages"], "exclude" => [] } }, files) do |site, destination|
      site.config["llms"] = { "markdown" => true, "llms_txt" => true, "include" => ["pages"], "exclude" => [] }
      yield site, destination
    end
  end

  def markdown_page
    <<~MARKDOWN
      ---
      layout: default
      title: Page
      render_with_liquid: false
      ---

      Page body.
    MARKDOWN
  end

  def with_recorded_logs
    writer = Struct.new(:warnings, :level) do
      def warn(message)
        warnings << message
      end

      def error(_message)
      end
    end.new([])
    original_writer = Jekyll.logger.writer
    original_level = original_writer.level
    Jekyll.logger = writer
    Jekyll.logger.log_level = :warn
    yield
    writer.warnings
  ensure
    Jekyll.logger = original_writer
    original_writer.level = original_level
  end

  def assert_recorded_warning(warnings, *parts)
    assert warnings.any? { |warning| parts.all? { |part| warning.include?(part) } }, warnings.inspect
  end
end
