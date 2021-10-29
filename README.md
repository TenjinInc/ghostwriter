# Ghostwriter

A ruby gem that converts HTML to plain text, preserving as much legibility and functionality as possible.

It's sort of like a reverse-markdown or a *very* simple screen reader.

## But Why, Though?

* Some email clients won't or can’t offer HTML support.
* Some people explicitly choose plaintext for accessibility or just plain preference.
* Spam filters tend to prefer emails with a plain text alternative (but if you use this gem to spam people, 
  not only might you be 
  [breaking](https://fightspam.gc.ca)
  [various](https://gdpr.eu/)
  [laws](https://www.ftc.gov/tips-advice/business-center/guidance/can-spam-act-compliance-guide-business), 
  I will also personally curse you)

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

Create a `Ghostwriter::Writer` and call `#textify` with the html string you want modified:

```ruby
html = <<~HTML
    <html>
    <body>
        <p>This is some text with <a href="tenjin.ca">a link</a></p>
        <p>It handles other stuff, too.</p>
        <hr>
        <h1>Stuff Like</h1>
        <ul>
          <li>Images</li>
          <li>Lists</li>
          <li>Tables</li>
          <li>And more</li>
        </ul>
    </body>
    </html>
HTML

ghostwriter = Ghostwriter::Writer.new

puts ghostwriter.textify(html)
```

Produces:

```
This is some text with a link (tenjin.ca)

It handles other stuff, too.


----------

-- Stuff Like --
- Images
- Lists
- Tables
- And more
```

### Links

Links are converted to the link text followed by the link target in brackets:

```html
Visit our <a href="https://example.com">Website</a>
```

Becomes:

```
Visit our Website (https://example.com)
```

#### Relative Links

Since emails are wholly distinct from your web address, relative links might break.

To avoid this problem, either use the `<base>` header tag:

```html

<html>
<head>
   <base href="https://www.example.com">
</head>
<body>
Use the base tag to <a href="/contact">expand</a> links.
</body>
</html>
```

Becomes:

```
Use the base tag to expand (https://www.example.com/contact) links.
```

Or you can use the `link_base` configuration:

```ruby
Ghostwriter::Writer.new(link_base: 'tenjin.ca').textify(html)
```

### Images

Images with alt text are converted:

```html
<img src="logo.jpg" alt="ACME Anvils" />
```

Becomes:

```
ACME Anvils (logo.jpg)
```

But images lacking alt text or with a presentation ARIA role are ignored:

```html
<!-- these will just become an empty string -->
<img src="decoration.jpg">
<img src="logo.jpg" role="presentation">
```

And images with data URIs won't include the data portion.

```html

<img src="data:image/gif;base64,R0lGODdhIwAjAMZ/AAkMBxETEBUUDBoaExkaGCIcFx4fGCEfFCcfECkjHiUlHiglGikmFjAqFi8pJCsrJT8sCjMzLDUzJzs0GjkzLTszKTM1Mzg4MD48Mzs+O0tAIElCJ1NCGVdBHUtEMkNFQjlHTFJDOkdGPT1ISUxLRENOT1tMI01PTGdLKk1RU0hTVEtTT0NVVFRTTExYWE9YVGhVP1VZXGFYTWhaMFRcWHFYL1FdXV1dRHdZMVRgYFhgXFdiY11hY1tkX31hJltmZ2pnWnloLGFrbG9oYXlqN3NqTnBqWHxqRItvRIh0Nod0ToF2U5J4LX55Xm97e4B5aZqAQpGAdqOCOZKEYZ2FOJyEVoyKbqiOXpySbLCVcLCXaKWbdKCdfZyhi66dksGdc76fbbije7mkdLOmgq6ogrCpibyvirexisWvhs2vgsGyiLq1lce1lMC5ks28nsfBmcHDq9bAl9PDmMnFo9TGh8zIoM7Jm9vLs9nRo93QqtfSquLQpdXUs+fdterlw////ywAAAAAIwAjAAAH/oArOTo6PYaGOz08P0KMOTZCOzw7PzY/Pz2JPYSDhTSFPTSXPY0tIiIfJz05o5Q/O7A5moc6O4Q0oS8uQisXGCItwTItP5OxOrKjhzSfLzYvgz85ERQXJKcSIkZeJDqOl43StrSEKzo2LhkOGBISDw40JyIVFVEyorBCkZmwtCsrtnLQSJCAwoMFCiwoiECPAr0TjPrtECJwXLMVNARlUCBhQAEFC2SsgWPGDBs3d2RcorSD1SVGr3qskOkihoIH70DO0cOHDx48evD0KQONmQ0aORZJE3VLRYoPBRwoUCCCSx07eoL+xLNnj5UfNFry4BHuR6EcK0qkKJFhAYUE/g+cdHlz1efPrnvM2MjhQlYOWTxktXThIoUKhQoKDHBi5Y0dO0CD5smzJ46NvWJfjYW1w4WKEiWkKkgw9UYdPXTo8Mn6042bvX9pTHoFa5GKzykekP5owEidN1u6PKnzMw+QJ3ttUPr7qKUs0C5KHOyoAMMaNWrmjKlSRYscMFm+nBBUybkLSYsIl3DxwAgcKwWMzGnz5kqTK1e09AEDI0uGE8rJEgNfsuxVggoujGABF1xMoYAVc9RRhxxq5JGVHn3EEYcIGfT1igvGKLfDZyWMkMINa5QhQRNz9CQhT1n5URmHJ8Sygw2BSWLDbaCpgEFPNzxBV4QwApVhHBhg/vABZ0pJIhuCoI0wQhFlkLEGGWfQ9wZ2W6KRBhoUJKncKyK2tMOBPI6wwAxltInlG1uKcQUUV3xpwQUXACSJjbCAxgJoJShggBVtnmGGlm/M4UYcX14QQQQ1PpJjUjmsd5sKCg5gBRdkYMlGG2KwoUYWWYARxgXVnODXqmP9CWgJIESwxhJTbEHGGGbMsSWpaRRBQQQXpPKIiJOgg+BnI4AwwhxcHFHrGGN0KYYYaEhAzQX/7flIDMqx4CoIJY7QxhpY0GorXXXwkUcRj1Lg7gfMDavcCSx4BqsIHpyxRhtT1FCDEmNgF4YY1j6KZ4eXXTast9GVcAIHG2TZRhlT/qCAAg5IZIzCA+1QQ0EGKbgAG7c0pPOAAgQcwEQSZ2R5RhlYVIFEFVccAQEAAASgWEIrXEZYDDHQYAEBAQSAcxBUbCExGWVsMfMVCHSA89QCbHBDX4QRRsPURuMcQBBQYLHGHGuwoYUYVdQQxAIOBCCACVLUgDMBS7rwwgtENHDAAEYLMIAAHhABRRVYKFEDDjjU0AA9HiQhxQQOCDC1BXe/UAQVVATRwAIDDGCAAAd0EAQTTEgBBQ4IIFSBFHFPdYEIFJBAQOUE1K5AAyZgnsQME/jNwAG/e7QBFT4sYEABBiQv6ANDDLDCCwPULr0ADYyeOQcMLMAAAxNAIQUHJwckYEDn5CfvgAEKvECA3+R7nrwB2k+ggQkmaLB3++Sz3zkMIawQCAA7"
     alt="Data picture" />
```

Becomes:

```
Data picture (embedded)
```

### Paragraphs and Linebreaks

Paragraphs are padded with a newline at the end. Line break tags add an empty line.

```html
<p>I would like to propose a toast.</p>
<p>This meal we enjoy together would be improved by one.</p>
<br />
<p>... Plug in the toaster and I'll get the bread.</p>
```

```
I would like to propose a toast.

This meal we enjoy together would be improved by one.


... Plug in the toaster and I'll get the bread.

```

### Headings

Headings are wrapped with a marker per heading level:

```html
<h1>Dog Maintenance and Repair</h1>
<h2>Food Input Port</h2>
<h3>Exhaust Port Considerations</h3>
```

Becomes:

```
-- Dog Maintenance and Repair --
---- Food Input Port ----
------ Exhaust Port Considerations ------
```

The `<header>` tag is treated like an `<h1>` tag.

### Lists

Lists are converted, too. They are padded with newlines and are given simple markers:

```html

<ul>
   <li>Planes</li>
   <li>Trains</li>
   <li>Automobiles</li>
</ul>
<ol>
   <li>I get knocked down</li>
   <li>I get up again</li>
   <li>Never gonna keep me down</li>
</ol>
```

Becomes:

```
- Planes
- Trains
- Automobiles

1. I get knocked down
2. I get up again
3. Never gonna keep me down
```

### Tables

Tables are still often used in email structuring because support for more modern HTML and CSS is inconsistent. If your
table is purely presentational, mark it with `role="presentation"`. See below for details.

For real data tables, Ghostwriter tries to maintain table structure for simple tables:

```html

<table>
   <thead>
   <tr>
      <th>Ship</th>
      <th>Captain</th>
   </tr>
   </thead>
   <tbody>
   <tr>
      <td>Enterprise</td>
      <td>Jean-Luc Picard</td>
   </tr>
   <tr>
      <td>TARDIS</td>
      <td>The Doctor</td>
   </tr>
   <tr>
      <td>Planet Express Ship</td>
      <td>Turanga Leela</td>
   </tr>
   </tbody>
</table>
```

Becomes:

```
| Ship                | Captain         |
|---------------------|-----------------|
| Enterprise          | Jean-Luc Picard |
| TARDIS              | The Doctor      |
| Planet Express Ship | Turanga Leela   |
```

### Customizing Output

Ghostwriter has some constructor options to customize output.

You can set heading markers.

```ruby
html = <<~HTML
   <h1>Emergency Cat Procedures</h1>
HTML

writer = Ghostwriter::Writer.new(heading_marker: '#')

puts writer.textify(html)
```

Produces:

```
# Emergency Cat Procedures #
```

You can also set list item markers. Ordered markers can be anything that responds to `#next` (eg. any `Enumerator`)

```ruby
html = <<~HTML
   <ol><li>Mercury</li><li>Venus</li><li>Mars</li></ol>
   <ul><li>Teapot</li><li>Kettle</li></ul>
HTML

writer = Ghostwriter::Writer.new(ul_marker: '*', ol_marker: 'a')

puts writer.textify(html)
```

Produces:

```
a. Mercury
b. Venus
c. Mars

* Teapot
* Kettle
```

And tables can be customized:

```ruby
writer = Ghostwriter::Writer.new(table_row:    '.',
                                 table_column: '#',
                                 table_corner: '+')

puts writer.textify <<~HTML
   <table>
      <thead>
         <tr><th>Moon</th><th>Portfolio</th></tr>
      </thead>
      <tbody>
         <tr><td>Phobos</td><td>Fear & Panic</td></tr>
         <tr><td>Deimos</td><td>Dread and Terror</td></tr>
      </tbody>
   </table>
HTML
```

Produces:

```
# Moon   # Portfolio        #
+........+..................+
# Phobos # Fear & Panic     #
# Deimos # Dread and Terror #

```

#### Presentation ARIA Role

Tags with `role="presentation"` will be treated as a simple container and the normal behaviour will be suppressed.

```html

<table role="presentation">
   <tr>
      <td>The table is a lie</td>
   </tr>
</table>
<ul role="presentation">
   <li>No such list</li>
</ul>
```

Becomes:

```
The table is a lie
No such list
```

### Mail Gem Example

To use `#textify` with the [mail](https://github.com/mikel/mail) gem, just provide the text-part by pasisng the html
through Ghostwriter:

```ruby
require 'mail'

html        = 'My email and a <a href="https://tenjin.ca">link</a>'
ghostwriter = Ghostwriter::Writer.new

Mail.deliver do
   to 'bob@example.com'
   from 'dot@example.com'
   subject 'Using Ghostwriter with Mail'

   html_part do
      content_type 'text/html; charset=UTF-8'
      body html
   end

   text_part do
      body ghostwriter.textify(html)
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

#### Local Install

To install this gem onto your local machine only, run

`bundle exec rake install`

#### Gem Release

To release a gem to the world at large

1. Update the version number in `version.rb`,
2. Run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push
   the `.gem` file to [rubygems.org](https://rubygems.org).
3. Do a wee dance

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
