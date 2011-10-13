require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'rubygems/package_task'

def common_test_settings(t)
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Default: run unit tests.'
task :default => :test

desc 'Test fuzzy_search.'
Rake::TestTask.new(:test) do |t|
  common_test_settings(t)
end

desc 'Run tests automatically as files change'
task :watchr do |t|
  exec 'watchr test/test.watchr'
end

desc 'Generate documentation for fuzzy_search.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'FuzzySearch'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'rcov/rcovtask'
  
  Rcov::RcovTask.new(:rcov) do |t|
    common_test_settings(t)
    t.rcov_opts << '-o coverage -x "/ruby/,/gems/,/test/,/migrate/"'
  end
rescue LoadError
  # Rcov wasn't available
end

begin
  require 'ruby-prof/task'
  
  RubyProf::ProfileTask.new(:profile) do |t|
    common_test_settings(t)
    t.output_dir = "#{File.dirname(__FILE__)}/profile"
    t.printer = :call_tree
    t.min_percent = 10
  end
rescue LoadError
  # Ruby-prof wasn't available
end

require 'lib/fuzzy_search_ver'
gemspec = Gem::Specification.new do |s|
  s.name         = "fuzzy_search"
  s.version      = FuzzySearch::VERSION
  s.authors      = ["Kristian Meier", "David Mike Simon"]
  s.email        = "david.mike.simon@gmail.com"
  s.homepage     = "http://github.com/DavidMikeSimon/fuzzy_search"
  s.summary      = "Search ActiveRecord models for strings similar to a query string"
  s.description  = "Implements fuzzy searching for ActiveRecord, using your database's own indexing instead of depending on external tools."

  s.files        = `git ls-files .`.split("\n") - [".gitignore"]
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'

  s.add_dependency('ar-extensions', '0.9.5')
end

Gem::PackageTask.new(gemspec) do |pkg|
end
