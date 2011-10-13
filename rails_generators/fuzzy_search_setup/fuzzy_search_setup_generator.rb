class FuzzySearchSetupGenerator < Rail::Generator::Base
  def manifest
    record do |m|
      m.migration_template "create_fuzzy_search_trigrams.rb", "db/migrate"
    end
  end
end
