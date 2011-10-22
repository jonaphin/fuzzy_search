require 'rubygems'
require 'faker'
require 'active_record'
require 'active_support'
require 'lib/split_trigrams.rb'

$KCODE = 'utf-8'

people_f = open("preloaded_people.csv", "w")
trigrams_f = open("preloaded_trigrams.csv", "w")

srand(1234)

1_000_000.times do |i|
  idx = i+1
  first_name, last_name = Faker::Name.first_name, Faker::Name.last_name
  people_f.puts([idx, first_name, last_name, 'Model airplanes'].join(','))

  trigrams = FuzzySearch::split_trigrams([first_name, last_name])
  trigrams.each do |tri|
    trigrams_f.puts([tri, 1, idx].join(','))
  end
end

types_f = open("preloaded_types.csv", "w")
types_f.puts('1,Person')

[people_f, trigrams_f, types_f].each(&:close)
