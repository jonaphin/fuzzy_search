require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require 'set'

describe "fuzzy search trigram splitter" do
  it "can split a string into trigrams with emphasized edges" do
    t = [" da", "dav", "avi", "vid", "id "]
    assert_equal Set.new(t), Set.new(FuzzySearch::split_trigrams("david"))
  end

  it "can normalize strings" do
    assert_equal([" a "], FuzzySearch::split_trigrams("À"))
  end

  it "can handle an array of strings" do
    t = [" x ", " y ", " zi", "zig", "ig "]
    assert_equal Set.new(t), Set.new(FuzzySearch::split_trigrams(["x", "y", "zig"]))
  end
end
