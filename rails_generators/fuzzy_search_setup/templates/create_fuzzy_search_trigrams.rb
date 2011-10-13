class CreateFuzzySearchTrigrams < ActiveRecord::Migration
  def self.up
    create_table :fuzzy_search_trigrams, :id => false do |t|
      t.column :token, :string, :limit => 3
      t.column :rec_type, :string
      t.column :rec_id, :integer
    end

    add_index :fuzzy_search_trigrams, [:rec_type, :token]
  end

  def self.down
    drop_table :fuzzy_search_trigrams
  end
end
