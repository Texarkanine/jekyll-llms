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
