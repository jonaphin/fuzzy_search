class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    is_mysql = ActiveRecord::Base.connection.adapter_name.downcase == 'mysql'
    table = '<%= table_name %>'.to_sym

    create_table table, :id => false do |t|
      t.column :subset, :integer, :limit => 4, :null => false
      if is_mysql
        t.column :token, "binary(3)", :null => false
      else
        t.column :token, :binary, :limit => 3, :null => false
      end
      t.column :rec_id, :integer, :null => false
    end

    if is_mysql
      ActiveRecord::Base.connection.execute(
        "ALTER TABLE #{table.to_s} ENGINE = MyISAM"
      )
    end
    add_index table, [:token, :subset, :rec_id], :name => "full_cover"
    add_index table, [:rec_id]

    <%= target_model_name %>.rebuild_fuzzy_search_index!
  end

  def self.down
    drop_table '<%= table_name %>'.to_sym
  end
end
