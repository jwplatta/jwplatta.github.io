# frozen_string_literal: true

source "https://rubygems.org"

gem "jekyll", "~> 4.3"
gem "jekyll-archives", "~> 2.2"
gem "jekyll-paginate", "~> 1.1"
gem "jekyll-seo-tag", "~> 2.8"
gem "jekyll-sitemap", "~> 1.4"
gem "jekyll-feed", "~> 0.17"
gem "jekyll-compose", group: [:jekyll_plugins]
gem "rouge", "~> 4.0"

group :test do
  gem "html-proofer", "~> 3.18"
end

# Windows and JRuby does not include zoneinfo files, so bundle the tzinfo-data gem
# and associated library.
platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end

gem "wdm", "~> 0.1.1", :platforms => [:mingw, :x64_mingw, :mswin]
gem "http_parser.rb", "~> 0.6.0", :platforms => [:jruby]

if RUBY_PLATFORM =~ /linux-musl/
  gem "jekyll-sass-converter", "~> 2.0"
end
