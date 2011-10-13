require 'fuzzy_search_ver'
require 'model_extensions'

ActiveRecord::Base.send(:include, FuzzySearch::ModelExtensions)
