class Person < ActiveRecord::Base
  fuzzy_searchable_on :first_name, :last_name, :subset_on => :favorite_number
end
