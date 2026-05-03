# frozen_string_literal: true

module Jekyll
  module Llms
    class SiteWriter
      def initialize(site)
        @site = site
        @config = Config.from_site(site)
        @entries = EntrySet.new(site: site, config: config).entries
        @files = FileWriter.new(site.dest)
      end

      def write
        write_index if config.llms_txt?
        if config.markdown?
          write_markdown
          write_html_links
        end
      end

      private

      attr_reader :site, :config, :entries, :files

      def write_index
        files.write("llms.txt", Index.new(site: site, entries: entries, markdown: config.markdown?).content)
      end

      def write_markdown
        markdown_entries.each do |entry|
          files.write(entry.url.markdown_path, MarkdownSource.new(site: site, item: entry.item).content)
        end
      end

      def write_html_links
        HtmlLinker.new(site: site, entries: markdown_entries).write
      end

      def markdown_entries
        entries.select(&:markdown_source?)
      end
    end
  end
end
