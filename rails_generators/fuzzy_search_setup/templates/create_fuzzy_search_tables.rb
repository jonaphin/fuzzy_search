class CreateFuzzySearchTables < ActiveRecord::Migration
  def self.up
    create_table :fuzzy_search_trigrams, :id => false do |t|
      t.column :token, :string, :limit => 3
      t.column :fuzzy_search_type_id, :integer
      t.column :rec_id, :integer
    end


    create_table :fuzzy_search_types do |t|
      t.column :type_name, :string
    end

    add_index :fuzzy_search_types, :type_name, :unique => true
  end

  def self.down
    drop_table :fuzzy_search_trigrams
    drop_table :fuzzy_search_types
  end
end
