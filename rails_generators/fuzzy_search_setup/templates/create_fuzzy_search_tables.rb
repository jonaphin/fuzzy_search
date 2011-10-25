class CreateFuzzySearchTables < ActiveRecord::Migration
  def self.up
    create_table :fuzzy_search_trigrams, :id => false do |t|
      t.column :token, :binary, :limit => 3, :null => false
      t.column :fuzzy_search_type_id, :integer, :null => false
      t.column :rec_id, :integer, :null => false
    end

    if ActiveRecord::Base.connection.adapter_name.downcase == 'mysql'
      ActiveRecord::Base.connection.execute(
        "alter table fuzzy_search_trigrams add primary key (fuzzy_search_type_id,token,rec_id)"
      )
    else
      add_index :fuzzy_search_trigrams, [:fuzzy_search_type_id, :token, :rec_id], :unique => true
    end
    add_index :fuzzy_search_trigrams, [:rec_id]

    create_table :fuzzy_search_types do |t|
      t.column :type_name, :string, :null => false
    end

    add_index :fuzzy_search_types, :type_name, :unique => true
  end

  def self.down
    drop_table :fuzzy_search_trigrams
    drop_table :fuzzy_search_types
  end
end
