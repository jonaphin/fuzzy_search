class FuzzySearchSetupGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.migration_template "create_fuzzy_search_trigrams.rb", "db/migrate",
        :migration_file_name => "create_fuzzy_search_trigrams"
    end
  end
end
