source "https://rubygems.org"

gem "jekyll", "~> 4.4"

group :jekyll_plugins do
  gem "jekyll-include-cache"
  gem "jekyll-feed"
  gem "jekyll-sitemap"
  gem "jekyll-gist"
  gem "jekyll-paginate"
end

# Bootstrap template dependency
gem "kramdown-parser-gfm", "~> 1.1"

# Local preview server
gem "webrick", "~> 1.7"

# Formerly-default stdlib gems dropped in Ruby 3.5+ / 4.0.
# Jekyll 4.4 already bundles base64, csv, json — these two it does not.
gem "logger"
gem "bigdecimal"