# frozen_string_literal: true

require 'spec_helper'

describe Ghostwriter::Writer do
   describe 'initialize' do
      # Immutability prevents accidental side-effects during operation.
      # Also it would give a tiny performance boost if you had a lot of them,
      # but that's unlikely for expected Ghostwriter usage.
      it 'should make the writer immutable' do
         expect(Ghostwriter::Writer.new).to be_frozen
      end

      it 'should provide config defaults' do
         expect(Ghostwriter::Writer.new).to be_a Ghostwriter::Writer
      end

      it 'should accept a link_base configuration' do
         base   = 'http://www.example.com'
         writer = Ghostwriter::Writer.new(link_base: base)

         expect(writer.link_base).to eq base
      end
   end

   describe '#textify' do
      let(:writer) { Ghostwriter::Writer.new }

      let :header_tags do
         %w{h1 h2 h3 h4 h5 h6 header}
      end

      it 'should always end output with a newline for clean concatenation' do
         html = ''

         expect(writer.textify(html)).to eq "\n"
      end

      it 'should compress whitespace to one space' do
         html = "\n\nThis   is\treally\nspaced\ttext"

         expect(writer.textify(html)).to eq <<~TEXT
            This is really spaced text
         TEXT
      end

      it 'should replace all <br> tags with a newline' do
         html = 'Line one<br>Line two'

         expect(writer.textify(html)).to eq <<~TEXT
            Line one
            Line two
         TEXT
      end

      it 'should whitespace strip each line after processing' do
         html = "<div>  \n  <p>Some text</p><p>  \n  more text  \n  </p>  </div>"

         expect(writer.textify(html)).to eq <<~TEXT
            Some text

            more text
         TEXT
      end

      context 'paragraphs' do
         it 'should pad paragraph endings with a newline' do
            html = '<p>I am a paragraph</p><p>Another one</p>'

            expect(writer.textify(html)).to eq <<~TEXT
               I am a paragraph

               Another one
            TEXT
         end

         it 'should consider raw text paragraphs' do
            html = <<~HTML
               I am a paragraph
               <p>Another one</p>
               And a third
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               I am a paragraph

               Another one

               And a third
            TEXT
         end
      end

      context 'horizontal rule' do
         it 'should replace hr with a line of dashes' do
            expect(writer.textify('<hr>')).to eq <<~TEXT
               ----------
            TEXT
         end

         it 'should pad hr with a blank line before it' do
            html = <<~HTML
               <h1>Words</h1><hr>
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               -- Words --

               ----------
            TEXT
         end

         it 'should pad hr with a blank line after it' do
            html = <<~HTML
               <hr>Words
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               ----------

               Words
            TEXT
         end
      end

      context 'links' do
         it 'should make links visible within brackets' do
            html = '<a href="www.example.com">A link</a>'

            expect(writer.textify(html)).to include 'A link (www.example.com)'
         end

         it 'should make links absolute addresses using base tag' do
            html = '<head><base href="www.example.com" /></head><body><a href="/relative/path">A link</a></body>'

            expect(writer.textify(html)).to include 'A link (www.example.com/relative/path)'
         end

         it 'should make links absolute addresses using given base' do
            html = '<a href="/relative/path">A link</a>'

            expect(Ghostwriter::Writer.new(link_base: 'www.example.com').textify(html)).to include 'A link (www.example.com/relative/path)'
         end

         it 'should not change absolute addresses when given base' do
            html = '<a href="http://www.example.com/absolute/path">A link</a>'

            expect(Ghostwriter::Writer.new(link_base: 'www.example2.com').textify(html)).to include 'A link (http://www.example.com/absolute/path)'

            html = '<head><base href="www.example2.com" /></head><body><a href="http://www.example.com/absolute/path">A link</a></body>'

            expect(writer.textify(html)).to include 'A link (http://www.example.com/absolute/path)'
         end

         # otherwise we get redundant "www.example.com (www.example.com)"
         it 'should only provide link target when target matches text' do
            html = <<~HTML
               <a href="www.example.com">www.example.com</a>
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               www.example.com
            TEXT
         end

         it 'should ignore HTTP when matching target to link text' do
            html = '<a href="http://www.example.com">www.example.com</a>'
            expect(writer.textify(html).chomp).to eq 'http://www.example.com'

            html = '<a href="www.example.com">http://www.example.com</a>'
            expect(writer.textify(html).chomp).to eq 'www.example.com'

            html = '<a href="http://www.example.com">http://www.example.com</a>'
            expect(writer.textify(html).chomp).to eq 'http://www.example.com'
         end

         it 'should ignore HTTPS when matching target to link text' do
            html = '<a href="https://www.example.com">www.example.com</a>'
            expect(writer.textify(html).chomp).to eq 'https://www.example.com'

            html = '<a href="www.example.com">https://www.example.com</a>'
            expect(writer.textify(html).chomp).to eq 'www.example.com'

            html = '<a href="https://www.example.com">https://www.example.com</a>'
            expect(writer.textify(html).chomp).to eq 'https://www.example.com'
         end

         # an alternative behaviour could be to always consider them matching,
         # and use the most specific, but this will work for now.
         it 'it should consider other schemes as distinct unless fully matching' do
            html = '<a href="ftp://www.example.com/">www.example.com/</a>'
            expect(writer.textify(html).chomp).to eq 'www.example.com/ (ftp://www.example.com/)'

            html = '<a href="www.example.com/">ftp://www.example.com/</a>'
            expect(writer.textify(html).chomp).to eq 'ftp://www.example.com/ (www.example.com/)'

            html = '<a href="ftp://www.example.com/">ftp://www.example.com/</a>'
            expect(writer.textify(html).chomp).to eq 'ftp://www.example.com/'
         end

         it 'should ignore trailing slash when matching target to link text' do
            # just take the link target as canonical
            html = '<a href="www.example.com/">www.example.com</a>'
            expect(writer.textify(html).chomp).to eq 'www.example.com/'

            html = '<a href="www.example.com">www.example.com/</a>'
            expect(writer.textify(html).chomp).to eq 'www.example.com'

            html = '<a href="www.example.com/">www.example.com/</a>'
            expect(writer.textify(html).chomp).to eq 'www.example.com/'
         end

         it 'should handle mailto scheme' do
            html = '<a href="mailto: hello@example.com">Email Us</a>'
            expect(writer.textify(html).chomp).to eq 'Email Us (hello@example.com)'
         end

         it 'should handle tel scheme' do
            html = '<a href="tel: +17805550123">Phone Us</a>'
            expect(writer.textify(html).chomp).to eq 'Phone Us (+17805550123)'

            html = '<a href="tel: +1.780.555.0123">Phone Us</a>'
            expect(writer.textify(html).chomp).to eq 'Phone Us (+1.780.555.0123)'
         end
      end

      context 'headers' do
         it 'should add a newline after headers' do
            header_tags.each do |tag|
               html = "<#{tag}>A header</#{tag}>"

               expect(writer.textify(html)).to end_with "\n"
            end
         end

         it 'should decorate headers' do
            header_tags.each do |tag|
               html = "<#{tag}>  A header  </#{tag}>"

               expect(writer.textify(html)).to eq <<~TEXT
                  -- A header --
               TEXT
            end
         end
      end

      context 'image' do
         it 'should replace images with alt text' do
            html = <<~HTML
               <img src="acme-logo.jpg" alt="ACME Anvils" />
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               ACME Anvils (acme-logo.jpg)
            TEXT
         end

         it 'should skip images without alt text' do
            html = <<~HTML
               <img src="flair.jpg" />
            HTML

            expect(writer.textify(html)).to eq "\n"
         end

         it 'should skip images with presentation role' do
            html = <<~HTML
               <img src="flair.jpg" alt="flair image" role=presentation />
               <img src="flair.jpg" alt="flair image" role="presentation" />
            HTML

            expect(writer.textify(html)).to eq "\n"
         end

         it 'should not include link target for data URI images' do
            html = <<~HTML
               <img src="data:image/gif;base64,R0lGODdhIwAjAMZ/AAkMBxETEBUUDBoaExkaGCIcFx4fGCEfFCcfECkjHiUlHiglGikmFjAqFi8pJCsrJT8sCjMzLDUzJzs0GjkzLTszKTM1Mzg4MD48Mzs+O0tAIElCJ1NCGVdBHUtEMkNFQjlHTFJDOkdGPT1ISUxLRENOT1tMI01PTGdLKk1RU0hTVEtTT0NVVFRTTExYWE9YVGhVP1VZXGFYTWhaMFRcWHFYL1FdXV1dRHdZMVRgYFhgXFdiY11hY1tkX31hJltmZ2pnWnloLGFrbG9oYXlqN3NqTnBqWHxqRItvRIh0Nod0ToF2U5J4LX55Xm97e4B5aZqAQpGAdqOCOZKEYZ2FOJyEVoyKbqiOXpySbLCVcLCXaKWbdKCdfZyhi66dksGdc76fbbije7mkdLOmgq6ogrCpibyvirexisWvhs2vgsGyiLq1lce1lMC5ks28nsfBmcHDq9bAl9PDmMnFo9TGh8zIoM7Jm9vLs9nRo93QqtfSquLQpdXUs+fdterlw////ywAAAAAIwAjAAAH/oArOTo6PYaGOz08P0KMOTZCOzw7PzY/Pz2JPYSDhTSFPTSXPY0tIiIfJz05o5Q/O7A5moc6O4Q0oS8uQisXGCItwTItP5OxOrKjhzSfLzYvgz85ERQXJKcSIkZeJDqOl43StrSEKzo2LhkOGBISDw40JyIVFVEyorBCkZmwtCsrtnLQSJCAwoMFCiwoiECPAr0TjPrtECJwXLMVNARlUCBhQAEFC2SsgWPGDBs3d2RcorSD1SVGr3qskOkihoIH70DO0cOHDx48evD0KQONmQ0aORZJE3VLRYoPBRwoUCCCSx07eoL+xLNnj5UfNFry4BHuR6EcK0qkKJFhAYUE/g+cdHlz1efPrnvM2MjhQlYOWTxktXThIoUKhQoKDHBi5Y0dO0CD5smzJ46NvWJfjYW1w4WKEiWkKkgw9UYdPXTo8Mn6042bvX9pTHoFa5GKzykekP5owEidN1u6PKnzMw+QJ3ttUPr7qKUs0C5KHOyoAMMaNWrmjKlSRYscMFm+nBBUybkLSYsIl3DxwAgcKwWMzGnz5kqTK1e09AEDI0uGE8rJEgNfsuxVggoujGABF1xMoYAVc9RRhxxq5JGVHn3EEYcIGfT1igvGKLfDZyWMkMINa5QhQRNz9CQhT1n5URmHJ8Sygw2BSWLDbaCpgEFPNzxBV4QwApVhHBhg/vABZ0pJIhuCoI0wQhFlkLEGGWfQ9wZ2W6KRBhoUJKncKyK2tMOBPI6wwAxltInlG1uKcQUUV3xpwQUXACSJjbCAxgJoJShggBVtnmGGlm/M4UYcX14QQQQ1PpJjUjmsd5sKCg5gBRdkYMlGG2KwoUYWWYARxgXVnODXqmP9CWgJIESwxhJTbEHGGGbMsSWpaRRBQQQXpPKIiJOgg+BnI4AwwhxcHFHrGGN0KYYYaEhAzQX/7flIDMqx4CoIJY7QxhpY0GorXXXwkUcRj1Lg7gfMDavcCSx4BqsIHpyxRhtT1FCDEmNgF4YY1j6KZ4eXXTast9GVcAIHG2TZRhlT/qCAAg5IZIzCA+1QQ0EGKbgAG7c0pPOAAgQcwEQSZ2R5RhlYVIFEFVccAQEAAASgWEIrXEZYDDHQYAEBAQSAcxBUbCExGWVsMfMVCHSA89QCbHBDX4QRRsPURuMcQBBQYLHGHGuwoYUYVdQQxAIOBCCACVLUgDMBS7rwwgtENHDAAEYLMIAAHhABRRVYKFEDDjjU0AA9HiQhxQQOCDC1BXe/UAQVVATRwAIDDGCAAAd0EAQTTEgBBQ4IIFSBFHFPdYEIFJBAQOUE1K5AAyZgnsQME/jNwAG/e7QBFT4sYEABBiQv6ANDDLDCCwPULr0ADYyeOQcMLMAAAxNAIQUHJwckYEDn5CfvgAEKvECA3+R7nrwB2k+ggQkmaLB3++Sz3zkMIawQCAA7" alt="Data image"/>
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               Data image (embedded)
            TEXT
         end
      end

      context 'list' do
         it 'should pad lists with a blank line before' do
            html = "Words<ul><li>Item</li></ul>"

            expect(writer.textify(html)).to eq <<~TEXT
               Words

               - Item
            TEXT

            html = "Words<ol><li>Item</li></ul>"

            expect(writer.textify(html)).to eq <<~TEXT
               Words

               1. Item
            TEXT
         end

         it 'should pad lists with a blank line after' do
            html = <<~HTML
               <ul><li>Item</li></ul>
               Words
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               - Item

               Words
            TEXT

            html = <<~HTML
               <ol><li>Item</li></ol>
               Words
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               1. Item

               Words
            TEXT
         end

         it 'should preface unordered list items with a bullet' do
            html = <<~HTML
               <ul>
                  <li>Planes</li>
                  <li>Trains</li>
                  <li>Automobiles</li>
               </ul>
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               - Planes
               - Trains
               - Automobiles
            TEXT
         end

         it 'should preface ordered list items with a number' do
            html = <<~HTML
               <ol>
                  <li>I get knocked down</li>
                  <li>I get up again</li>
                  <li>Never gonna keep me down</li>
               </ol>
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               1. I get knocked down
               2. I get up again
               3. Never gonna keep me down
            TEXT
         end
      end

      context 'tables' do
         it 'should bracket th and td with pipes' do
            html = <<~HTML
               <table>
                  <tbody>
                     <tr>
                        <th>Enterprise</th>
                        <td>Jean-Luc Picard</td>
                     </tr>
                  </tbody>
               </table>
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               | Enterprise | Jean-Luc Picard |
            TEXT
         end

         it 'should underline header rows' do
            html = <<~HTML
               <table>
                  <thead>
                     <tr>
                        <th>Enterprise</th>
                        <td>Jean-Luc Picard</td>
                     </tr>
                  </thead>
               </table>
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               | Enterprise | Jean-Luc Picard |
               |------------|-----------------|
            TEXT
         end

         it 'should assume tbody if not specified' do
            html = <<~HTML
               <table>
                  <tr>
                     <td>Enterprise</td>
                     <td>Jean-Luc Picard</td>
                  </tr>
               </table>
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               | Enterprise | Jean-Luc Picard |
            TEXT
         end

         it 'should add newline after table' do
            html = <<~HTML
               <table>
                  <tr>
                     <td>Enterprise</td>
                     <td>Jean-Luc Picard</td>
                  </tr>
               </table>
               <table>
                  <tr>
                     <td>TARDIS</td>
                     <td>The Doctor</td>
                  </tr>
               </table>
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               | Enterprise | Jean-Luc Picard |

               | TARDIS | The Doctor |
            TEXT
         end

         it 'should match column sizes' do
            html = <<~HTML
               <table>
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
               </table>
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               | Enterprise          | Jean-Luc Picard |
               | TARDIS              | The Doctor      |
               | Planet Express Ship | Turanga Leela   |
            TEXT
         end

         it 'should match column sizes per table' do
            html = <<~HTML
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
                  </tbody>
               </table>

               <table>
                  <thead>
                     <tr>
                        <th>Ship</th>
                        <th>Captain</th>
                     </tr>
                  </thead>
                  <tbody>
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
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               | Ship       | Captain         |
               |------------|-----------------|
               | Enterprise | Jean-Luc Picard |
               | TARDIS     | The Doctor      |

               | Ship                | Captain       |
               |---------------------|---------------|
               | TARDIS              | The Doctor    |
               | Planet Express Ship | Turanga Leela |
            TEXT
         end

         it 'should parse fully defined tables' do
            html = <<~HTML
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
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               | Ship                | Captain         |
               |---------------------|-----------------|
               | Enterprise          | Jean-Luc Picard |
               | TARDIS              | The Doctor      |
               | Planet Express Ship | Turanga Leela   |
            TEXT
         end
      end

      context 'tag removal' do
         it 'should entirely remove style tags' do
            html = '<style>a {color: blue;}</style>'

            expect(writer.textify(html)).to eq "\n"
         end

         it 'should remove script tags' do
            html = '<script>someJsCode()</script>'

            expect(writer.textify(html)).to eq "\n"
         end

         it 'should remove all other html elements' do
            %w{div strong b i}.each do |tag|
               html = "<#{ tag }></#{ tag }>"

               expect(writer.textify(html)).to eq "\n"
            end
         end
      end

      context 'aria presentation role' do
         it 'should treat cells in table with presentation role as paragraphs' do
            html = <<~HTML
               <table role="presentation"><tr><td>With quotes</td></tr></table>
               <table role=presentation><tr><td>No quotes</td></tr></table>
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               With quotes
               No quotes
            TEXT
         end

         it 'should treat list with presentation role as paragraphs' do
            html = <<~HTML
               <ol role="presentation"><li>Ordered with quotes</li></ol>
               <ol role=presentation><li>Ordered without quotes</li></ol>

               <ul role="presentation"><li>Unordered with quotes</li></ul>
               <ul role=presentation><li>Unordered without quotes</li></ul>
            HTML

            expect(writer.textify(html)).to eq <<~TEXT
               Ordered with quotes
               Ordered without quotes
               Unordered with quotes
               Unordered without quotes
            TEXT
         end
      end

      context 'entity interpretation' do
         it 'should interpret whitespace entities' do
            html = '<html>&nbsp;</html>'

            nbsp = [160].pack('U*')

            expect(writer.textify(html)).to eq <<~TEXT
               #{ nbsp }
            TEXT
         end

         it 'should interpret symbol entities' do
            html = '<html>&lt;&gt;&amp;&quot;</html>'

            expect(writer.textify(html)).to eq <<~TEXT
               <>&"
            TEXT
         end

         it 'should interpret unicode hex entities' do
            html = "&#x267b;"

            expect(writer.textify(html)).to eq <<~TEXT
               \u267b
            TEXT
         end

         it 'should interpret unicode decimal entities' do
            html = "&#9851;"

            expect(writer.textify(html)).to eq <<~TEXT
               \u267b
            TEXT
         end
      end
   end
end
