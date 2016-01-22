# Dirt::Textify

Textify transforms HTML into plaintext while preserving as much legibility and functionality as possible. It's prime use is in quickly producing an automatic plaintext version of HTML emails. 

Why offer plaintext? 

 * Spam filters prefer included plain text alternative 
 * Some email clients and apps can’t handle HTML
 * Some people explicitly choose plaintext, either for visual impairment or simple preference

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dirt-textify'
```

And then execute:

    $ bundle

Or install it manually with:

    $ gem install dirt-textify

## Usage

Just call `Dirt::Textify.textify` and pass in the html you want distilled:

```ruby
html = '<html><body>This is some markup <a href="tenjin.ca">and a link</a><p>Other tags translate, too</p></body></html>'

Dirt::Textify.textify(html)

=> "This is some markup and a link (tenjin.ca)\nOther tags translate, too\n\n" 
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/TenjinInc/dirt-textify. This project is intended to be a welcoming collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
