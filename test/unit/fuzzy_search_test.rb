require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

describe "fuzzy_search" do
  before do 
    create(:person, :last_name => "meier", :first_name => "kristian")
    create(:person, :last_name => "meyer", :first_name => "christian")
    create(:person, :last_name => "mayr", :first_name => "Chris")
    create(:person, :last_name => "maier", :first_name => "christoph")
    create(:person, :last_name => "mueller", :first_name => "andreas")
    create(:person, :last_name => "öther", :first_name => "name")
    create(:person, :last_name => "yet another", :first_name => "name")

    create(:email, :address => "öscar@web.oa")
    create(:email, :address => "david.mike.simon@gmail.com")
    create(:email, :address => "billg@microsoft.com")
  end

  it "can search an indexed ActiveRecord model for similar strings" do
    assert_equal 3, User.fuzzy_search("meyr").size
    assert_equal 1, User.fuzzy_search("myr").size
    result = User.fuzzy_search("kristian meier")
    assert_equal "kristian", result[0].firstname
    assert_equal "meier", result[0].surname
    assert_equal 100, result[0].fuzzy_weight
    (1..3).each do |idx|
      assert result[idx].fuzzy_weight < 100
    end
    assert_equal 0, User.fuzzy_search("").size
  end

  it "updates the index automatically when a record is saved" do
    # TODO
  end

  it "only finds records of the ActiveRecord model you're searching on" do
    assert User.fuzzy_search("meier").size > 0
    assert_equal 0, Email.fuzzy_search("meier").size
    assert User.fuzzy_search("kristian").size > 0
    assert_equal 0, Email.fuzzy_search("kristian").size
    assert_equal 0, User.fuzzy_search("oscar").size
    assert Email.fuzzy_search("oscar").size > 0
  end

  it "normalizes strings before searching on them or indexing them" do
    assert_equal("aaaaaa", User.normalize("ÀÁÂÃÄÅ"))

    assert_equal 4, User.fuzzy_search("chris").size
    assert_equal 1, User.fuzzy_search("muell").size
    assert_equal 1, User.fuzzy_search("Müll").size
    assert_equal 1, User.fuzzy_search("mull").size
    assert_equal 1, User.fuzzy_search("other").size
    assert_equal 1, Email.fuzzy_search("öscar").size
    assert_equal 1, Email.fuzzy_search("oscar").size
  end

  it "deletes search index entries when a record is deleted" do
    size = User.fuzzy_search("other").size
    assert size > 0, "some entries"
    User.first(:surname => "other").destroy
    assert_equal size, User.fuzzy_search("other").size + 1
  end

  it "can search through a scope" do
    # TODO
  end
end