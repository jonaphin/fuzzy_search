# fuzzy_search

Search through your models while tolerating slight mis-spellings. If you have a Person in your database named O'Reilly, you want your users to be able to find it even if they type "OReilly" or "O'Rielly".

This gem is not as powerful as dedicated search tools like Solr, but it's much easier to set up and more appropriate for searching small strings, such names of people or products. It uses your regular database, rather than an external service that has to be maintained separately.

Currently only Rails 2 is supported. I welcome any contributions that resolve this!

## Installation

Add `fuzzy_search` to your Rails project's Gemfile, and do the usual `bundle install` dance.

## Example

To allow a model to be searched, specify which columns are to be searched on:

```ruby
class Person < ActiveRecord::Base
    # ...
    fuzzy_searchable_on :first_name, :last_name
    # ...
end
```
And then create a search table, and the initial trigrams, for that model:

    $ ./script/generate fuzzy_search_table Person
    $ rake db:migrate

The fuzzy_search method returns search results:

```ruby
people = Person.fuzzy_search "OReilly"
```
It works thru scopes too, including named_scopes and on-the-fly scopes:

```ruby
people = Person.scoped({:conditions => ["state='active'"]}).fuzzy_search("OReilly")
```

If you have a very large data set but are typically searching for items
within a scoped subset of that data, you can get a significant performance
boost for those searches by having FuzzySearch include the scope-defining
field (which currently must be an integer) in the search table:

```ruby
class Person < ActiveRecord::Base
    # ...
    fuzzy_searchable_on :first_name, :last_name, :subset_on => :zipcode
    # ...
end

bev_hills_people = Person.fuzzy_search("OReilly", :subset => {:zipcode => 90210})
```

## Licence and credits

This gem is based on the rails-fuzzy-search plugin by iulianu
(https://github.com/iulianu/rails-fuzzy-search), which was in
turn based on the act_as_fuzzy_search plugin for DataMapper
by mkristian (http://github.com/mkristian/kristians_rails_plugins).

This gem is available under the MIT Licence.
