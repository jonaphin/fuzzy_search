require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

describe "fuzzy_search" do
  if ENV["BENCH"]
    before do
      Person.set_table_name "preloaded_people"
      FuzzySearchTrigram.set_table_name "preloaded_trigrams"
      FuzzySearchType.set_table_name "preloaded_types"
    end

    after do
      Person.set_table_name "people"
      FuzzySearchTrigram.set_table_name "fuzzy_search_trigrams"
      FuzzySearchType.set_table_name "fuzzy_search_types"
    end

    bench_performance_linear "queries" do |n|
      srand(n)
      n.times do
        Person.scoped(:limit => 20).fuzzy_search(Faker::Name.last_name)
      end
    end
  end
end
