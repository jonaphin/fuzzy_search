# require 'lib/fuzzy_search_ver'
gemspec = Gem::Specification.new do |s|
  s.name         = "fuzzy_search"
  s.version      = "0.4"
  s.authors      = ["Kristian Meier", "David Mike Simon"]
  s.email        = "david.mike.simon@gmail.com"
  s.homepage     = "http://github.com/DavidMikeSimon/fuzzy_search"
  s.summary      = "Search ActiveRecord models for strings similar to a query string"
  s.description  = "Implements fuzzy searching for ActiveRecord, using your database's own indexing instead of depending on external tools."

  s.files        = `git ls-files .`.split("\n") - [".gitignore"]
  # s.files        = ["lib/fuzzy_model_extensions", "lib/fuzzy_search", "lib/fuzzy_search_ver", "lib/split_trigrams", "lib/trigram_model_extensions"]
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'

  # s.add_dependency('ar-extensions', '0.9.5')
end

# Gem::PackageTask.new(gemspec) do |pkg|
# end
