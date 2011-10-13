# fuzzy_search

Search through your models while tolerating slight mis-spellings. If you have a Person in your database named O'Reilly, you want your users to be able to find it even if they type "OReilly" or "O'Rielly".

This gem is not as powerful as dedicated search tools like Solr, but it's much quicker and easier to set up. It uses your regular database for indexing, rather than an external service that has to be maintained separately.

Currently only Rails 2 is supported. I welcome any contributions that resolve this!

## Installation

Add `fuzzy_search` to your Rails project's Gemfile, and do the usual `bundle install` dance.

Then, run the generator and migrate to create the search table:

    $ ./script/generate fuzzy_search_setup
    $ rake db:migrate

## Example

To allow a model to be searched, specify which columns are to be indexed:

```ruby
class Person < ActiveRecord::Base
    # ...
    fuzzy_searchable_on :first_name, :last_name
    # ...
end
```
Now, the gem will update the index whenever a Person is saved. To index all the existing records in a model, do this:

```ruby
Person.rebuild_fuzzy_search_index!
```

The fuzzy_search method returns arrays:

```ruby
people = Person.fuzzy_search "OReilly"
```

Fuzzy find works on scopes too, including named_scopes and on-the-fly scopes:

```ruby
people = Person.scoped({:conditions => ["state='active'"]}).fuzzy_search("OReilly")
```

## Licence and credits

This gem is based on the rails-fuzzy-search plugin by iulianu
(https://github.com/iulianu/rails-fuzzy-search), which was in
turn based on the act_as_fuzzy_search plugin for DataMapper
by mkristian (http://github.com/mkristian/kristians_rails_plugins).

This gem is available under the MIT Licence.
