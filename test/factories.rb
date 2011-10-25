require 'factory_girl'

FactoryGirl.define do
  factory :person do
    first_name 'John'
    last_name 'Doe'
    hobby 'Flying kites'
    sequence(:favorite_number) {|n| (n%3) + 1 }
  end

  factory :email do
    address 'foo@bar.com'
  end
end
