# PropsRb

Ember.js style properties in Ruby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'props_rb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install props_rb

## Usage


```ruby
  class Person
    include HashByGuid
    include PropsRb
    prop :first_name
    prop :last_name

    prop :full_name do |obj|
      "#{obj.get(:first_name)} #{obj.get(:last_name)}"
    end.depends_on(:first_name, :last_name)

    def initialize
      initialize_props
    end
  end

  person = Person.create first_name: "Billy", last_name: "Bob", guid: 8
  p person.get(:full_name)
  person.set(:first_name, "Darth")
  person.set(:last_name, "Vader")
  p person.get(:full_name)
  p person.get('full_name')

  person.prop :wah do |obj|
    "#{obj.get(:first_name)} monkey"
  end.depends_on(:first_name)

  p person.get(:wah)
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/props_rb/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
