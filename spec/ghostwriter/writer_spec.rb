# frozen_string_literal: true

require 'spec_helper'

describe Ghostwriter::Writer do
   describe '#textify' do
      let :header_tags do
         %w{h1 h2 h3 h4 h5 h6 header}
      end

      it 'should replace hr with a line of dashes' do
         html = '<hr>'

         expect(Ghostwriter::Writer.new.textify(html)).to eq "\n----------\n"
      end

      context 'links' do
         it 'should make links visible within brackets' do
            html = '<a href="www.example.com">A link</a>'

            expect(Ghostwriter::Writer.new.textify(html)).to include 'A link (www.example.com)'
         end

         it 'should make links absolute addresses using base tag' do
            html = '<head><base href="www.example.com" /></head><body><a href="/relative/path">A link</a></body>'

            expect(Ghostwriter::Writer.new.textify(html)).to include 'A link (www.example.com/relative/path)'
         end

         it 'should make links absolute addresses using given base' do
            html = '<a href="/relative/path">A link</a>'

            expect(Ghostwriter::Writer.new(link_base: 'www.example.com').textify(html)).to include 'A link (www.example.com/relative/path)'
         end

         it 'should not change absolute addresses when given base' do
            html = '<a href="http://www.example.com/absolute/path">A link</a>'

            expect(Ghostwriter::Writer.new(link_base: 'www.example2.com').textify(html)).to include 'A link (http://www.example.com/absolute/path)'

            html = '<head><base href="www.example2.com" /></head><body><a href="http://www.example.com/absolute/path">A link</a></body>'

            expect(Ghostwriter::Writer.new.textify(html)).to include 'A link (http://www.example.com/absolute/path)'
         end

         # otherwise we get redundant "www.example.com (www.example.com)"
         it 'should only provide link target when target matches text' do
            html = '<a href="www.example.com">www.example.com</a>'

            expect(Ghostwriter::Writer.new.textify(html)).to eq 'www.example.com'
         end

         it 'should ignore HTTP when matching target to link text' do
            html = '<a href="http://www.example.com">www.example.com</a>'
            expect(Ghostwriter::Writer.new.textify(html)).to eq 'http://www.example.com'

            html = '<a href="www.example.com">http://www.example.com</a>'
            expect(Ghostwriter::Writer.new.textify(html)).to eq 'www.example.com'

            html = '<a href="http://www.example.com">http://www.example.com</a>'
            expect(Ghostwriter::Writer.new.textify(html)).to eq 'http://www.example.com'
         end

         it 'should ignore HTTPS when matching target to link text' do
            html = '<a href="https://www.example.com">www.example.com</a>'
            expect(Ghostwriter::Writer.new.textify(html)).to eq 'https://www.example.com'

            html = '<a href="www.example.com">https://www.example.com</a>'
            expect(Ghostwriter::Writer.new.textify(html)).to eq 'www.example.com'

            html = '<a href="https://www.example.com">https://www.example.com</a>'
            expect(Ghostwriter::Writer.new.textify(html)).to eq 'https://www.example.com'
         end

         # an alternative behaviour could be to always consider them matching,
         # and use the most specific, but this will work for now.
         it 'it should consider other schemes as distinct unless fully matching' do
            html = '<a href="ftp://www.example.com/">www.example.com/</a>'
            expect(Ghostwriter::Writer.new.textify(html)).to eq 'www.example.com/ (ftp://www.example.com/)'

            html = '<a href="www.example.com/">ftp://www.example.com/</a>'
            expect(Ghostwriter::Writer.new.textify(html)).to eq 'ftp://www.example.com/ (www.example.com/)'

            html = '<a href="ftp://www.example.com/">ftp://www.example.com/</a>'
            expect(Ghostwriter::Writer.new.textify(html)).to eq 'ftp://www.example.com/'
         end

         it 'should ignore trailing slash when matching target to link text' do
            # just take the link target as canonical
            html = '<a href="www.example.com/">www.example.com</a>'
            expect(Ghostwriter::Writer.new.textify(html)).to eq 'www.example.com/'

            html = '<a href="www.example.com">www.example.com/</a>'
            expect(Ghostwriter::Writer.new.textify(html)).to eq 'www.example.com'

            html = '<a href="www.example.com/">www.example.com/</a>'
            expect(Ghostwriter::Writer.new.textify(html)).to eq 'www.example.com/'
         end

         it 'should handle mailto scheme' do
            html = '<a href="mailto: hello@example.com">Email Us</a>'
            expect(Ghostwriter::Writer.new.textify(html)).to eq 'Email Us (hello@example.com)'
         end

         it 'should handle tel scheme' do
            html = '<a href="tel: +17805550123">Phone Us</a>'
            expect(Ghostwriter::Writer.new.textify(html)).to eq 'Phone Us (+17805550123)'

            html = '<a href="tel: +1.780.555.0123">Phone Us</a>'
            expect(Ghostwriter::Writer.new.textify(html)).to eq 'Phone Us (+1.780.555.0123)'
         end
      end

      context 'headers' do
         it 'should add a newline after headers' do
            header_tags.each do |tag|
               html = "<#{tag}>A header</#{tag}>"

               expect(Ghostwriter::Writer.new.textify(html)).to end_with "\n"
            end
         end

         it 'should decorate headers' do
            header_tags.each do |tag|
               html = "<#{tag}>  A header  </#{tag}>"

               expect(Ghostwriter::Writer.new.textify(html)).to eq <<~TEXT
                  -- A header --
               TEXT
            end
         end
      end

      it 'should compress whitespace to one space' do
         html = "\n\nThis   is\treally\nspaced\ttext"

         expect(Ghostwriter::Writer.new.textify(html)).to eq 'This is really spaced text'
      end

      it 'should replace all <br> tags with newlines' do
         html = 'Line one<br>Line two'

         expect(Ghostwriter::Writer.new.textify(html)).to eq "Line one\nLine two"
      end

      it 'should replace paragraph end tags with double newlines' do
         html = '<p>I am a paragraph</p>'

         expect(Ghostwriter::Writer.new.textify(html)).to eq "I am a paragraph\n\n"
      end

      it 'should strip each line after processing' do
         html = "<div>  \n  <p>Some text</p><p>  \n  more text  \n  </p>  </div>"

         expect(Ghostwriter::Writer.new.textify(html)).to eq "Some text\n\nmore text\n\n"
      end

      context 'image' do
         it 'should replace images with alt text' do
            html = <<~HTML
               <img src="acme-logo.jpg" alt="ACME Anvils" />
            HTML

            expect(Ghostwriter::Writer.new.textify(html)).to eq 'ACME Anvils (acme-logo.jpg)'
         end

         it 'should skip images without alt text' do
            html = <<~HTML
               <img src="flair.jpg" />
            HTML

            expect(Ghostwriter::Writer.new.textify(html)).to be_empty
         end

         it 'should skip images with presentation role' do
            html = <<~HTML
               <img src="flair.jpg" alt="flair image" role=presentation />
               <img src="flair.jpg" alt="flair image" role="presentation" />
            HTML

            expect(Ghostwriter::Writer.new.textify(html)).to be_empty
         end
      end

      context 'list' do
         it 'should buffer lists with newlines' do
            %w[ul ol].each do |tag|
               html = "<#{ tag }></#{ tag }>"

               expect(Ghostwriter::Writer.new.textify(html)).to eq "\n\n"
            end
         end

         it 'should preface unordered list items with a bullet' do
            html = <<~HTML
               <ul>
                  <li>Planes</li>
                  <li>Trains</li>
                  <li>Automobiles</li>
               </ul>
            HTML

            expect(Ghostwriter::Writer.new.textify(html)).to eq <<~TEXT

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

            expect(Ghostwriter::Writer.new.textify(html)).to eq <<~TEXT

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

            expect(Ghostwriter::Writer.new.textify(html)).to eq <<~TEXT
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

            expect(Ghostwriter::Writer.new.textify(html)).to eq <<~TEXT
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

            expect(Ghostwriter::Writer.new.textify(html)).to eq <<~TEXT
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

            expect(Ghostwriter::Writer.new.textify(html)).to eq <<~TEXT
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

            expect(Ghostwriter::Writer.new.textify(html)).to eq <<~TEXT
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

            expect(Ghostwriter::Writer.new.textify(html)).to eq <<~TEXT
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

            expect(Ghostwriter::Writer.new.textify(html)).to eq <<~TEXT
               | Ship                | Captain         |
               |---------------------|-----------------|
               | Enterprise          | Jean-Luc Picard |
               | TARDIS              | The Doctor      |
               | Planet Express Ship | Turanga Leela   |

            TEXT
         end
      end

      context 'tag removal' do
         it 'should remove style tags' do
            html = '<style>a {color: blue;}</style>'

            expect(Ghostwriter::Writer.new.textify(html)).to eq ''
         end

         it 'should remove script tags' do
            html = '<script>someJsCode()</script>'

            expect(Ghostwriter::Writer.new.textify(html)).to be_empty
         end

         it 'should remove all other html elements' do
            %w{div strong b i}.each do |tag|
               html = "<#{ tag }></#{ tag }>"

               expect(Ghostwriter::Writer.new.textify(html)).to be_empty
            end
         end
      end

      context 'aria presentation role' do
         it 'should treat cells in table with presentation role as paragraphs' do
            html = <<~HTML
               <table role="presentation"><tr><td>With quotes</td></tr></table>
               <table role=presentation><tr><td>No quotes</td></tr></table>
            HTML

            expect(Ghostwriter::Writer.new.textify(html)).to eq <<~TEXT
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

            expect(Ghostwriter::Writer.new.textify(html)).to eq <<~TEXT
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

            expect(Ghostwriter::Writer.new.textify(html)).to eq nbsp
         end

         it 'should interpret symbol entities' do
            html = '<html>&lt;&gt;&amp;&quot;</html>'

            expect(Ghostwriter::Writer.new.textify(html)).to eq '<>&"'
         end

         it 'should interpret unicode hex entities' do
            html = "&#x267b;"

            expect(Ghostwriter::Writer.new.textify(html)).to eq "\u267b"
         end

         it 'should interpret unicode decimal entities' do
            html = "&#9851;"

            expect(Ghostwriter::Writer.new.textify(html)).to eq "\u267b"
         end
      end
   end
end
