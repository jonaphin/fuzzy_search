class Email < ActiveRecord::Base
  fuzzy_searchable_on :address
end
