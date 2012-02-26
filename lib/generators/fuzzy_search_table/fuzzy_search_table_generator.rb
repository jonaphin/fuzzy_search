class FuzzySearchTableGenerator < Rails::Generators::NamedBase
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)
  argument :name, :type => :string

  def self.next_migration_number(path)
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  end

  def generate_fuzzy_search_table
    @target_model_name = name.classify
    @table_name = "#{name.underscore}_fuzzy_search_trigrams"
    @migration_filename = "create_#{name.underscore}_fuzzy_search_table"
    @migration_name = @migration_filename.classify

    migration_template "fuzzy_search_table.rb", "db/migrate/#{@migration_filename}", target_model_name: @target_model_name
  end
end
