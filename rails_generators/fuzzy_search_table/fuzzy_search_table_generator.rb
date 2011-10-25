class FuzzySearchTableGenerator < Rails::Generator::NamedBase
  attr_reader :target_model_name
  attr_reader :table_name
  attr_reader :migration_filename
  attr_reader :migration_name

  def initialize(runtime_args, runtime_options = {})
    super
    @target_model_name = name.classify
    @table_name = "#{name.underscore}_fuzzy_search_trigrams"
    @migration_filename = "create_#{name.underscore}_fuzzy_search_table"
    @migration_name = migration_filename.classify
  end

  def manifest
    record do |m|
      m.migration_template "create_fuzzy_search_table.rb", "db/migrate",
        :migration_file_name => migration_filename
    end
  end
end
