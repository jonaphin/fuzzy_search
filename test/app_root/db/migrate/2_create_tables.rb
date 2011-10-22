class CreateTables < ActiveRecord::Migration
  def self.up
    create_table :emails do |t|
      t.string :address
    end

    create_table :people do |t|
      t.string :first_name
      t.string :last_name
      t.string :hobby
    end
  end
  
  def self.down
    drop_table :emails
    drop_table :people
  end
end
