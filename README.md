# Ghostwriter

Ghostwriter rewrites HTML as plain text while preserving as much legibility and functionality as possible.

It's sort of like a reverse-markdown.

## But Why, Though?

* Spam filters tend to like emails with a plain text alternative
* Some email clients won't or can’t handle HTML at all
* Some people explicitly choose plaintext just by preference or accessibility

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ghostwriter'
```

And then execute:

    bundle

Or install it manually with:

    gem install ghostwriter

## Usage

Create a `Ghostwriter::Writer` with the html you want modified, and call `#textify`:

```ruby
html = '<html><body>This is some markup <a href="tenjin.ca">and a link</a><p>Other tags translate, too</p></body></html>'

Ghostwriter::Writer.new(html).textify

=> "This is some markup and a link (tenjin.ca)\nOther tags translate, too\n\n"

```

`#textify` will use the `<base>` tag if found in the HTML source, or if one is provided explicitly:

```ruby
html = '<html><body>Relative links <a href="/contact">Link</a></body></html>'

Ghostwriter::Writer.new(html).textify(link_base: 'tenjin.ca')

=> "Relative links Link (tenjin.ca/contact)"

```

### Mail Gem Example

To use `#textify` with the [mail](https://github.com/mikel/mail) gem, just provide the text-part by pasisng the html
through Ghostwriter:

```ruby
require 'mail'

html = 'My email and a <a href="http://tenjin.ca">link</a>'

mail = Mail.deliver do
   to 'bob@example.com'
   from 'dot@example.com'
   subject 'Using Ghostwriter with Mail'

   html_part do
      content_type 'text/html; charset=UTF-8'
      body html
   end

   text_part do
      body Ghostwriter::Writer.new(html).textify
   end
end

```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/TenjinInc/ghostwriter

This project is intended to be a friendly space for collaboration, and contributors are expected to adhere to the
[Contributor Covenant](contributor-covenant.org) code of conduct.

### Core Developers

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to run the tests. You
can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
