# frozen_string_literal: true

require 'spec_helper'

describe Ghostwriter::Writer do
   describe '#textify' do
      let :header_tags do
         %w{h1 h2 h3 h4 h5 h6 header}
      end

      it 'should replace hr with a line of dashes' do
         html = '<hr>'

         expect(Ghostwriter::Writer.new(html).textify).to eq "\n----------\n"
      end

      context 'links' do
         it 'should make links visible within brackets' do
            html = '<a href="www.example.com">A link</a>'

            expect(Ghostwriter::Writer.new(html).textify).to include 'A link (www.example.com)'
         end

         it 'should make links absolute addresses using base tag' do
            html = '<head><base href="www.example.com" /></head><body><a href="/relative/path">A link</a></body>'

            expect(Ghostwriter::Writer.new(html).textify).to include 'A link (www.example.com/relative/path)'
         end

         it 'should make links absolute addresses using given base' do
            html = '<a href="/relative/path">A link</a>'

            expect(Ghostwriter::Writer.new(html).textify(link_base: 'www.example.com')).to include 'A link (www.example.com/relative/path)'
         end

         it 'should not change absolute addresses when given base' do
            html = '<a href="http://www.example.com/absolute/path">A link</a>'

            expect(Ghostwriter::Writer.new(html).textify(link_base: 'www.example2.com')).to include 'A link (http://www.example.com/absolute/path)'

            html = '<head><base href="www.example2.com" /></head><body><a href="http://www.example.com/absolute/path">A link</a></body>'

            expect(Ghostwriter::Writer.new(html).textify).to include 'A link (http://www.example.com/absolute/path)'
         end

         # otherwise we get redundant "www.example.com (www.example.com)"
         it 'should only provide link target when target matches text' do
            html = '<a href="www.example.com">www.example.com</a>'

            expect(Ghostwriter::Writer.new(html).textify).to eq 'www.example.com'
         end

         it 'should ignore HTTP when matching target to link text' do
            html = '<a href="http://www.example.com">www.example.com</a>'
            expect(Ghostwriter::Writer.new(html).textify).to eq 'http://www.example.com'

            html = '<a href="www.example.com">http://www.example.com</a>'
            expect(Ghostwriter::Writer.new(html).textify).to eq 'www.example.com'

            html = '<a href="http://www.example.com">http://www.example.com</a>'
            expect(Ghostwriter::Writer.new(html).textify).to eq 'http://www.example.com'
         end

         it 'should ignore HTTPS when matching target to link text' do
            html = '<a href="https://www.example.com">www.example.com</a>'
            expect(Ghostwriter::Writer.new(html).textify).to eq 'https://www.example.com'

            html = '<a href="www.example.com">https://www.example.com</a>'
            expect(Ghostwriter::Writer.new(html).textify).to eq 'www.example.com'

            html = '<a href="https://www.example.com">https://www.example.com</a>'
            expect(Ghostwriter::Writer.new(html).textify).to eq 'https://www.example.com'
         end

         # an alternative behaviour could be to always consider them matching,
         # and use the most specific, but this will work for now.
         it 'it should consider other schemes as distinct unless fully matching' do
            html = '<a href="ftp://www.example.com/">www.example.com/</a>'
            expect(Ghostwriter::Writer.new(html).textify).to eq 'www.example.com/ (ftp://www.example.com/)'

            html = '<a href="www.example.com/">ftp://www.example.com/</a>'
            expect(Ghostwriter::Writer.new(html).textify).to eq 'ftp://www.example.com/ (www.example.com/)'

            html = '<a href="ftp://www.example.com/">ftp://www.example.com/</a>'
            expect(Ghostwriter::Writer.new(html).textify).to eq 'ftp://www.example.com/'
         end

         it 'should ignore trailing slash when matching target to link text' do
            # just take the link target as canonical
            html = '<a href="www.example.com/">www.example.com</a>'
            expect(Ghostwriter::Writer.new(html).textify).to eq 'www.example.com/'

            html = '<a href="www.example.com">www.example.com/</a>'
            expect(Ghostwriter::Writer.new(html).textify).to eq 'www.example.com'

            html = '<a href="www.example.com/">www.example.com/</a>'
            expect(Ghostwriter::Writer.new(html).textify).to eq 'www.example.com/'
         end
      end

      context 'headers' do
         it 'should add a newline after headers' do
            header_tags.each do |tag|
               html = "<#{tag}>A header</#{tag}>"

               expect(Ghostwriter::Writer.new(html).textify).to end_with "\n"
            end
         end

         it 'should decorate headers' do
            header_tags.each do |tag|
               html = "<#{tag}>  A header  </#{tag}>"

               expect(Ghostwriter::Writer.new(html).textify).to start_with '- A header -'
            end
         end
      end

      it 'should compress whitespace to one space' do
         html = "\n\nThis   is\treally\nspaced\ttext"

         expect(Ghostwriter::Writer.new(html).textify).to eq 'This is really spaced text'
      end

      it 'should replace all <br> tags with newlines' do
         html = 'Line one<br>Line two'

         expect(Ghostwriter::Writer.new(html).textify).to eq "Line one\nLine two"
      end

      it 'should replace paragraph end tags with double newlines' do
         html = '<p>I am a paragraph</p>'

         expect(Ghostwriter::Writer.new(html).textify).to eq "I am a paragraph\n\n"
      end

      # TODO: it should handle tables in a clean way.

      it 'should strip each line after processing' do
         html = "<div>  \n  <p>Some text</p><p>  \n  more text  \n  </p>  </div>"

         expect(Ghostwriter::Writer.new(html).textify).to eq "Some text\n\nmore text\n\n"
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

            expect(Ghostwriter::Writer.new(html).textify).to eq <<~HTML
               | Enterprise | Jean-Luc Picard |

            HTML
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

            expect(Ghostwriter::Writer.new(html).textify).to eq <<~HTML
               | Enterprise | Jean-Luc Picard |
               |------------|-----------------|

            HTML
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

            expect(Ghostwriter::Writer.new(html).textify).to eq <<~HTML
               | Enterprise | Jean-Luc Picard |

            HTML
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

            expect(Ghostwriter::Writer.new(html).textify).to eq <<~HTML
               | Enterprise | Jean-Luc Picard |

               | TARDIS | The Doctor |

            HTML
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

            expect(Ghostwriter::Writer.new(html).textify).to eq <<~HTML
               | Enterprise          | Jean-Luc Picard |
               | TARDIS              | The Doctor      |
               | Planet Express Ship | Turanga Leela   |

            HTML
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

            expect(Ghostwriter::Writer.new(html).textify).to eq <<~HTML
               | Ship       | Captain         |
               |------------|-----------------|
               | Enterprise | Jean-Luc Picard |
               | TARDIS     | The Doctor      |

               | Ship                | Captain       |
               |---------------------|---------------|
               | TARDIS              | The Doctor    |
               | Planet Express Ship | Turanga Leela |

            HTML
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

            expect(Ghostwriter::Writer.new(html).textify).to eq <<~HTML
               | Ship                | Captain         |
               |---------------------|-----------------|
               | Enterprise          | Jean-Luc Picard |
               | TARDIS              | The Doctor      |
               | Planet Express Ship | Turanga Leela   |

            HTML
         end
      end

      context 'tag removal' do
         it 'should remove style tags' do
            html = '<style>a {color: blue;}</style>'

            expect(Ghostwriter::Writer.new(html).textify).to eq ''
         end

         it 'should remove script tags' do
            html = '<script>someJsCode()</script>'

            expect(Ghostwriter::Writer.new(html).textify).to be_empty
         end

         it 'should remove all other html elements' do
            %w{div strong b i}.each do |tag|
               html = "<#{tag}></#{tag}>"

               expect(Ghostwriter::Writer.new(html).textify).to be_empty
            end
         end
      end

      context 'entity interpretation' do
         it 'should interpret whitespace entities' do
            html = '<html>&nbsp;</html>'

            nbsp = [160].pack('U*')

            expect(Ghostwriter::Writer.new(html).textify).to eq nbsp
         end

         it 'should interpret symbol entities' do
            html = '<html>&lt;&gt;&amp;&quot;</html>'

            expect(Ghostwriter::Writer.new(html).textify).to eq '<>&"'
         end

         it 'should interpret unicode hex entities' do
            html = "&#x267b;"

            expect(Ghostwriter::Writer.new(html).textify).to eq "\u267b"
         end

         it 'should interpret unicode decimal entities' do
            html = "&#9851;"

            expect(Ghostwriter::Writer.new(html).textify).to eq "\u267b"
         end
      end
   end
end
