require 'rubygems'
require 'faker'
require 'active_record'
require 'active_support'
require 'lib/split_trigrams.rb'

$KCODE = 'utf-8'

people_f = open("preloaded_people.csv", "w")
trigrams_f = open("preloaded_person_fuzzy_search_trigrams.csv", "w")

srand(1234)

1_000_000.times do |i|
  idx = i+1
  first_name, last_name = Faker::Name.first_name, Faker::Name.last_name
  fav_num = rand(100)+1
  people_f.puts([idx, first_name, last_name, 'Model airplanes', fav_num].join(","))

  trigrams = FuzzySearch::split_trigrams([first_name, last_name])
  trigrams.each do |tri|
    trigrams_f.puts([fav_num, tri, idx].join(","))
  end
end

[people_f, trigrams_f].each(&:close)
