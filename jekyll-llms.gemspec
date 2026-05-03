# frozen_string_literal: true

require_relative "lib/jekyll/llms/version"

Gem::Specification.new do |spec|
  spec.name = "jekyll-llms"
  spec.version = Jekyll::Llms::VERSION
  spec.authors = ["Stanislav Katkov"]
  spec.email = ["git@skatkov.com"]

  spec.summary = "Generate LLM-friendly files for Jekyll sites."
  spec.description = "Generates llms.txt and Markdown sidecars for Jekyll pages and posts."
  spec.homepage = "https://github.com/skatkov/jekyll-llms"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.metadata = {
    "allowed_push_host" => "https://rubygems.org",
    "homepage_uri" => spec.homepage,
    "rubygems_mfa_required" => "true",
    "source_code_uri" => spec.homepage
  }

  spec.files = Dir["lib/**/*", "README.md", "CHANGELOG.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "jekyll", ">= 4.0", "< 5.0"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "mutant", "~> 0.16"
  spec.add_development_dependency "mutant-minitest", "~> 0.16"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
