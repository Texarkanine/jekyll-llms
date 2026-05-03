# frozen_string_literal: true

module Jekyll
  module Llms
    class Entry
      attr_reader :item, :section, :url

      def initialize(site:, item:, section:)
        @site = site
        @item = item
        @section = section
        @url = Url.new(site: site, item: item)
      end

      def description
        item.data.fetch("description", "").strip
      end

      def enabled?
        item.data.fetch("llms", true)
      end

      def markdown_source?
        markdown_extensions.include?(File.extname(item.relative_path).delete_prefix("."))
      end

      def excluded_by?(patterns)
        patterns.any? do |pattern|
          url.matches?(pattern)
        end
      end

      def title
        title = item.data.fetch("title", "").strip
        return title unless title.empty?

        fallback_title
      end

      private

      attr_reader :site

      def markdown_extensions
        site.config.fetch("markdown_ext", Configuration::DEFAULTS.fetch("markdown_ext")).split(",")
      end

      def fallback_title
        if item.respond_to?(:basename_without_ext)
          item.basename_without_ext
        else
          File.basename(item.name, ".*")
        end
      end

    end
  end
end
