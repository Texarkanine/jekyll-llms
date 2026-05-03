# frozen_string_literal: true

require "test_helper"

class JekyllLlmsTest < Minitest::Test
  def test_generates_llms_txt_and_markdown_sidecars
    build_site({}, default_files) do |_site, destination|
      llms_txt = read_output(destination, "llms.txt")

      assert_includes llms_txt, "# Fixture Site"
      assert_includes llms_txt, "> Fixture description."
      assert_includes llms_txt, "## Pages"
      assert_includes llms_txt, "- [Home](https://example.com/base/index.md): Home page."
      assert_includes llms_txt, "- [Documentation](https://example.com/base/docs.md): Docs page."
      assert_includes llms_txt, "## Posts"
      assert_includes llms_txt, "- [Newer post](https://example.com/base/blog/newer.md): Fresh post."
      assert_includes llms_txt, "- [Older post](https://example.com/base/blog/older.md)"

      assert_operator llms_txt.index("Newer post"), :<, llms_txt.index("Older post")

      refute_includes llms_txt, "Hidden post"
      refute_includes llms_txt, "Secret"
      refute_includes llms_txt, "Not Found"
      refute_includes llms_txt, "Asset"

      assert_equal "<h1>Fixture Site</h1>\n", read_output(destination, "index.md")
      assert_equal "# Docs\n\nWelcome to Fixture Site.\n", read_output(destination, "docs.md")
      assert_equal "Newer Fixture Site.\n", read_output(destination, "blog/newer.md")
      assert_equal "Older post body.\n", read_output(destination, "blog/older.md")

      refute_path_exists output_path(destination, "secret.md")
      refute_path_exists output_path(destination, "404.md")
      refute_path_exists output_path(destination, "assets/asset.md")
      refute_path_exists output_path(destination, "blog/hidden.md")
    end
  end

  def test_uses_original_urls_when_markdown_generation_is_disabled
    config = {
      "baseurl" => "",
      "llms" => {
        "markdown" => false,
        "llms_txt" => true,
        "include" => %w[pages posts],
      },
    }

    build_site(config, {
      "plain.md" => <<~MARKDOWN,
        ---
        title: Plain Page
        ---

        Plain page body.
      MARKDOWN
      "_posts/2024-01-01-post.md" => <<~MARKDOWN,
        ---
        title: Plain Post
        ---

        Plain post body.
      MARKDOWN
    }) do |_site, destination|
      llms_txt = read_output(destination, "llms.txt")

      assert_includes llms_txt, "- [Plain Page](https://example.com/plain)"
      assert_includes llms_txt, "- [Plain Post](https://example.com/blog/post)"

      refute_path_exists output_path(destination, "plain.md")
      refute_path_exists output_path(destination, "blog/post.md")
    end
  end

  def test_can_disable_llms_txt_while_keeping_markdown_sidecars
    config = {
      "llms" => {
        "markdown" => true,
        "llms_txt" => false,
        "include" => ["pages"],
      },
    }

    build_site(config, {
      "page.md" => <<~MARKDOWN,
        ---
        title: Page
        ---

        Page body.
      MARKDOWN
    }) do |_site, destination|
      refute_path_exists output_path(destination, "llms.txt")
      assert_equal "Page body.\n", read_output(destination, "page.md")
    end
  end

  def test_includes_output_collections_and_fallback_titles
    config = {
      "collections" => {
        "guides" => {
          "output" => true,
          "permalink" => "/guides/:name",
        },
      },
      "llms" => {
        "markdown" => true,
        "llms_txt" => true,
        "include" => ["pages", "guides"],
      },
    }

    build_site(config, {
      "untitled.html" => <<~HTML,
        ---
        ---

        <p>Untitled page.</p>
      HTML
      "data.json" => <<~JSON,
        ---
        title: Data
        ---

        {"name":"fixture"}
      JSON
      "_guides/intro.md" => <<~MARKDOWN,
        ---
        title: ""
        ---

        Collection body.
      MARKDOWN
    }) do |_site, destination|
      llms_txt = read_output(destination, "llms.txt")

      assert_includes llms_txt, "## Guides"
      assert_includes llms_txt, "- [untitled](https://example.com/base/untitled.md)"
      assert_includes llms_txt, "- [Data](https://example.com/base/data.md)"
      assert_includes llms_txt, "- [intro](https://example.com/base/guides/intro.md)"

      assert_equal "<p>Untitled page.</p>\n", read_output(destination, "untitled.md")
      assert_equal "{\"name\":\"fixture\"}\n", read_output(destination, "data.md")
      assert_equal "Collection body.\n", read_output(destination, "guides/intro.md")
    end
  end

  def test_skips_non_output_collections
    config = {
      "collections" => {
        "components" => {
          "output" => false,
        },
      },
      "llms" => {
        "markdown" => true,
        "llms_txt" => true,
        "include" => ["components"],
      },
    }

    build_site(config, {
      "_components/card.md" => <<~MARKDOWN,
        ---
        title: Card
        ---

        Card body.
      MARKDOWN
    }) do |_site, destination|
      llms_txt = read_output(destination, "llms.txt")

      refute_includes llms_txt, "Card"
      refute_path_exists output_path(destination, "components/card.md")
    end
  end

  private

  def default_files
    {
      "index.html" => <<~HTML,
        ---
        title: Home
        description: Home page.
        ---

        <h1>{{ site.title }}</h1>
      HTML
      "docs.md" => <<~MARKDOWN,
        ---
        title: Documentation
        description: Docs page.
        ---

        # Docs

        Welcome to {{ site.title }}.
      MARKDOWN
      "secret.md" => <<~MARKDOWN,
        ---
        title: Secret
        llms: false
        ---

        Secret body.
      MARKDOWN
      "404.html" => <<~HTML,
        ---
        title: Not Found
        ---

        <h1>Missing</h1>
      HTML
      "assets/asset.md" => <<~MARKDOWN,
        ---
        title: Asset
        ---

        Asset body.
      MARKDOWN
      "_posts/2024-01-03-hidden.md" => <<~MARKDOWN,
        ---
        title: Hidden post
        llms: false
        ---

        Hidden body.
      MARKDOWN
      "_posts/2024-01-02-newer.md" => <<~MARKDOWN,
        ---
        title: Newer post
        description: Fresh post.
        ---

        Newer {{ site.title }}.
      MARKDOWN
      "_posts/2024-01-01-older.md" => <<~MARKDOWN,
        ---
        title: Older post
        ---

        Older post body.
      MARKDOWN
    }
  end
end
