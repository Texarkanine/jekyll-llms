# frozen_string_literal: true

require "fileutils"
require "jekyll"
require "jekyll/llms/version"

module Jekyll
  module Llms
    DEFAULT_CONFIG = {
      "markdown" => true,
      "llms_txt" => true,
      "include" => %w[pages posts],
      "exclude" => [],
    }.freeze

    Entry = Struct.new(:item, :section, keyword_init: true)

    class << self
      def write(site)
        config = llms_config(site)
        entries = entries_for(site, config)

        write_llms_txt(site, entries, config) if config["llms_txt"]
        write_markdown_files(site, entries) if config["markdown"]
      end

      private

      def llms_config(site)
        user_config = site.config.fetch("llms", {}) || {}
        DEFAULT_CONFIG.merge(user_config).tap do |config|
          config["include"] = Array(config["include"])
          config["exclude"] = Array(config["exclude"])
        end
      end

      def entries_for(site, config)
        config["include"].flat_map do |section|
          items_for(site, section.to_s).map do |item|
            Entry.new(item: item, section: section.to_s)
          end
        end.select do |entry|
          include_entry?(entry, config)
        end.uniq do |entry|
          entry.item.url
        end
      end

      def items_for(site, section)
        case section
        when "pages"
          site.pages
        when "posts"
          site.posts.docs.sort { |a, b| b <=> a }
        else
          collection = site.collections[section]
          return [] unless collection&.write?

          collection.docs
        end
      end

      def include_entry?(entry, config)
        return false if entry.item.data["llms"] == false
        return false if entry.item.respond_to?(:published?) && !entry.item.published?

        !excluded?(entry, config["exclude"])
      end

      def excluded?(entry, patterns)
        candidates = [entry.item.url, markdown_url(entry.item), relative_source_path(entry.item), source_path(entry.item)].compact

        patterns.any? do |pattern|
          candidates.any? do |candidate|
            glob_match?(pattern.to_s, candidate.to_s)
          end
        end
      end

      def glob_match?(pattern, candidate)
        flags = File::FNM_PATHNAME | File::FNM_EXTGLOB
        File.fnmatch?(pattern, candidate, flags) ||
          File.fnmatch?(pattern.delete_prefix("/"), candidate.delete_prefix("/"), flags)
      end

      def write_llms_txt(site, entries, config)
        path = File.join(site.dest, "llms.txt")
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, llms_txt(site, entries, config), mode: "wb")
      end

      def llms_txt(site, entries, config)
        lines = ["# #{site.config["title"] || "Jekyll Site"}"]

        description = site.config["description"].to_s.strip
        lines << ""
        lines << "> #{description}" unless description.empty?

        entries.group_by(&:section).each do |section, section_entries|
          lines << ""
          lines << "## #{section_title(section)}"
          lines << ""

          section_entries.each do |entry|
            lines << llms_txt_entry(site, entry, config)
          end
        end

        lines << ""
        lines.join("\n")
      end

      def llms_txt_entry(site, entry, config)
        item = entry.item
        url = config["markdown"] ? markdown_url(item) : item.url
        line = "- [#{title(item)}](#{absolute_url(site, url)})"
        description = item.data["description"].to_s.strip

        description.empty? ? line : "#{line}: #{description}"
      end

      def write_markdown_files(site, entries)
        entries.each do |entry|
          path = File.join(site.dest, markdown_url(entry.item))
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, source_body(site, entry.item), mode: "wb")
        end
      end

      def source_body(site, item)
        path = source_path(item)
        return "" unless path && File.file?(path)

        content = File.read(path, **Jekyll::Utils.merged_file_read_opts(site, {}))
        content = Regexp.last_match.post_match if content =~ Jekyll::Document::YAML_FRONT_MATTER_REGEXP
        content = render_liquid(site, item, content, path) if render_with_liquid?(item, content)

        "#{content.sub(/\A\n+/, "").rstrip}\n"
      end

      def render_liquid(site, item, content, path)
        payload = site.site_payload
        payload["page"] = item.to_liquid
        payload["paginator"] = item.pager.to_liquid if item.respond_to?(:pager) && item.pager
        payload["site"].current_document = item if payload["site"].respond_to?(:current_document=)

        liquid_options = site.config["liquid"] || {}
        info = {
          registers: { site: site, page: payload["page"] },
          strict_filters: liquid_options["strict_filters"],
          strict_variables: liquid_options["strict_variables"],
        }

        Jekyll::Renderer.new(site, item).render_liquid(content, payload, info, path)
      end

      def render_with_liquid?(item, content)
        item.data["render_with_liquid"] != false && Jekyll::Utils.has_liquid_construct?(content)
      end

      def source_path(item)
        return item.path if item.respond_to?(:path) && File.file?(item.path)
        return item.site.in_source_dir(item.relative_path) if item.respond_to?(:relative_path)
      end

      def relative_source_path(item)
        return unless item.respond_to?(:relative_path)

        "/#{item.relative_path.delete_prefix("/")}"
      end

      def markdown_url(item)
        url = item.url.to_s
        return "/index.md" if url == "/"
        return "#{url}index.md" if url.end_with?("/")
        return "#{url}.md" if File.extname(url).empty?

        dirname = File.dirname(url)
        basename = File.basename(url, ".*")
        File.join(dirname, "#{basename}.md").sub(%r!\A\./!, "/")
      end

      def absolute_url(site, path)
        url = site.config["url"].to_s.chomp("/")
        baseurl = site.config["baseurl"].to_s.chomp("/")
        relative_path = "/#{path.to_s.delete_prefix("/")}"

        "#{url}#{baseurl}#{relative_path}"
      end

      def title(item)
        title = item.data["title"].to_s.strip
        return title unless title.empty?

        if item.respond_to?(:basename_without_ext)
          item.basename_without_ext
        else
          File.basename(item.name.to_s, ".*")
        end
      end

      def section_title(section)
        section.split(/[_-]/).map(&:capitalize).join(" ")
      end
    end
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  Jekyll::Llms.write(site)
end
