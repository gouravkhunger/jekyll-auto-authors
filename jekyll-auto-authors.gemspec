# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jekyll-auto-authors/version"
require "date"

Gem::Specification.new do |spec|
  spec.name          = "jekyll-auto-authors"
  spec.version       = Jekyll::AutoAuthors::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.required_ruby_version = ">= 2.0.0"  # Same as Jekyll
  spec.date          = DateTime.now.strftime("%Y-%m-%d")
  spec.authors       = ["Gourav Khunger"]
  spec.email         = ["gouravkhunger18@gmail.com"]
  spec.homepage      = "https://github.com/gouravkhunger/jekyll-auto-authors"
  spec.license       = "MIT"

  spec.summary       = "Seamless multiple authors support for jekyll powered publications"
  spec.description   = "A plugin to seamlessly support multiple authors with paginated posts inside a jekyll powered publication blog. Extends jekyll-paginate-v2 for Autopages and Pagination."

  spec.files          = Dir["*.gemspec", "Gemfile", "lib/**/*"]
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_runtime_dependency "jekyll", ">= 3.0.0"
  spec.add_runtime_dependency "jekyll-paginate-v2", ">= 3.0.0"
  spec.add_development_dependency "bundler", ">= 2.0.0"
end
