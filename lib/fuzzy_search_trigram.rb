class FuzzySearchTrigram < ActiveRecord::Base
  # This isn't used directly very much; too much overhead in AR.
  # However, we still need it to use with ar-extensions for import.
end
