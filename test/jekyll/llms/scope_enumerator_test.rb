# frozen_string_literal: true

require "test_helper"

class JekyllLlmsScopeEnumeratorTest < Minitest::Test
  cover "Jekyll::Llms::ScopeEnumerator"
  cover "Jekyll::Llms::Scope"

  # One scope per site.categories key; entries intersect root EntrySet; path uses template + slug.
  def test_builds_category_scopes_from_site_categories
    kept = item(url: "/blog/kept")
    other = item(url: "/blog/other")
    entry = entry_for(kept, section: "posts")
    site = site(
      categories: { "My Category" => [kept], "empty" => [other] },
      config: { "url" => "https://example.com", "baseurl" => "" }
    )
    config = config(categories: true)

    scopes = scopes_for(site: site, config: config, entries: [entry])

    assert_equal 1, scopes.length
    scope = scopes.first
    assert_equal "/category/my-category/", scope.path_prefix
    assert_equal "My Category", scope.title
    assert_equal "Category: My Category", scope.description
    assert_equal [entry], scope.entries
  end

  # Uses jekyll-archives category permalink template when configured.
  def test_uses_archives_category_path_template
    post = item(url: "/blog/post")
    entry = entry_for(post, section: "posts")
    site = site(
      categories: { "fable" => [post] },
      config: {
        "url" => "https://example.com",
        "baseurl" => "",
        "jekyll-archives" => { "permalinks" => { "category" => "/topics/:name/" } },
      }
    )

    scopes = scopes_for(site: site, config: config(categories: true), entries: [entry])

    assert_equal "/topics/fable/", scopes.first.path_prefix
  end

  # One scope per included writeable collection label (not pages/posts); path /{label}/.
  def test_builds_collection_scopes_for_included_writeable_collections
    doc = item(url: "/garden/note")
    entry = entry_for(doc, section: "garden")
    site = site(
      collections: {
        "garden" => collection(docs: [doc], write: true),
        "drafts" => collection(docs: [item(url: "/drafts/x")], write: false),
      },
      config: { "url" => "https://example.com", "baseurl" => "" }
    )
    config = config(collection_indexes: true, include: %w[pages posts garden])

    scopes = scopes_for(site: site, config: config, entries: [entry])

    assert_equal 1, scopes.length
    scope = scopes.first
    assert_equal "/garden/", scope.path_prefix
    assert_equal "garden", scope.title
    assert_equal "Collection: garden", scope.description
    assert_equal [entry], scope.entries
  end

  # Flags off yield no scopes.
  def test_returns_empty_when_flags_off
    post = item(url: "/blog/post")
    entry = entry_for(post, section: "posts")
    site = site(
      categories: { "fable" => [post] },
      collections: { "garden" => collection(docs: [item(url: "/garden/n")], write: true) },
      config: { "url" => "https://example.com", "baseurl" => "" }
    )

    assert_empty scopes_for(site: site, config: config, entries: [entry])
  end

  # Zero-entry scopes after intersection are omitted.
  def test_omits_scopes_with_zero_entries
    outside = item(url: "/blog/outside")
    site = site(
      categories: { "fable" => [outside] },
      config: { "url" => "https://example.com", "baseurl" => "" }
    )
    kept = entry_for(item(url: "/blog/kept"), section: "posts")

    assert_empty scopes_for(site: site, config: config(categories: true), entries: [kept])
  end

  private

  def scopes_for(site:, config:, entries:)
    Jekyll::Llms::ScopeEnumerator.new(site: site, config: config, entries: entries).scopes
  end

  def config(categories: false, collection_indexes: false, include: %w[pages posts])
    Jekyll::Llms::Config.new(
      Jekyll::Llms::Config::DEFAULTS.merge(
        "categories" => categories,
        "collection_indexes" => collection_indexes,
        "include" => include
      )
    )
  end

  def site(categories: {}, collections: {}, config:)
    Struct.new(:categories, :collections, :config, :pages, :posts).new(
      categories,
      collections,
      config,
      [],
      Struct.new(:docs).new([])
    )
  end

  def entry_for(item, section:)
    Jekyll::Llms::Entry.new(
      site: Struct.new(:config).new({ "url" => "https://example.com", "baseurl" => "" }),
      item: item,
      section: section
    )
  end

  def item(url:, relative_path: nil, data: {}, name: nil)
    relative_path ||= "#{url.delete_prefix("/")}.md"
    name ||= File.basename(relative_path)
    Struct.new(:url, :relative_path, :data, :name).new(url, relative_path, data, name)
  end

  def collection(docs:, write:)
    Class.new do
      attr_reader :docs

      def initialize(docs, write)
        @docs = docs
        @write = write
      end

      def write?
        @write
      end
    end.new(docs, write)
  end
end
