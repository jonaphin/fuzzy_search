require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

describe "fuzzy_search" do
  if ENV["BENCH"]
    before do
      Person.set_table_name "preloaded_people"
      FuzzySearchTrigram.set_table_name "preloaded_trigrams"
      FuzzySearchType.set_table_name "preloaded_types"

      # Force Person to reload its fuzzy type id from preloaded_types
      Person.send(:write_inheritable_attribute, :fuzzy_search_cached_type_id, nil)
    end

    after do
      Person.set_table_name "people"
      FuzzySearchTrigram.set_table_name "fuzzy_search_trigrams"
      FuzzySearchType.set_table_name "fuzzy_search_types"
    end

    bench_range do
      [1, 10, 50]
    end

    bench_performance_linear "queries", 0.9 do |n|
      c = 0
      n.times do
        result = Person.scoped(:limit => 20).fuzzy_search(Faker::Name.last_name)
        c += result.size
      end
      if n >= 30
        rpq = c/(n.to_f)
        if rpq < 2
          raise "Sanity check failure, average results per query: #{rpq}"
        end
      end
    end
  end
end
