require 'spec_helper'

describe Dirt::Textify::Decoder do
   describe '#textify' do
      let :header_tags do
         %w{h1 h2 h3 h4 h5 h6 header}
      end

      it 'should replace hr with a line of dashes' do
         html = '<hr>'

         expect(Dirt::Textify::Decoder.new(html).textify).to eq "\n----------\n"
      end

      context 'links' do
         it 'should make links visible within brackets' do
            html = '<a href="www.example.com">A link</a>'

            expect(Dirt::Textify::Decoder.new(html).textify).to include 'A link (www.example.com)'
         end

         it 'should make links absolute addresses using base tag' do
            html = '<head><base href="www.example.com" /></head><body><a href="/relative/path">A link</a></body>'

            expect(Dirt::Textify::Decoder.new(html).textify).to include 'A link (www.example.com/relative/path)'
         end

         it 'should make links absolute addresses using given base' do
            html = '<a href="/relative/path">A link</a>'

            expect(Dirt::Textify::Decoder.new(html).textify(link_base: 'www.example.com')).to include 'A link (www.example.com/relative/path)'
         end

         it 'should not change absolute addresses when given base' do
            html = '<a href="http://www.example.com/absolute/path">A link</a>'

            expect(Dirt::Textify::Decoder.new(html).textify(link_base: 'www.example2.com')).to include 'A link (http://www.example.com/absolute/path)'

            html = '<head><base href="www.example2.com" /></head><body><a href="http://www.example.com/absolute/path">A link</a></body>'

            expect(Dirt::Textify::Decoder.new(html).textify).to include 'A link (http://www.example.com/absolute/path)'
         end
      end

      context 'headers' do
         it 'should add a newline after headers' do
            header_tags.each do |tag|
               html = "<#{tag}>A header</#{tag}>"

               expect(Dirt::Textify::Decoder.new(html).textify).to end_with "\n"
            end
         end

         it 'should decorate headers' do
            header_tags.each do |tag|
               html = "<#{tag}>  A header  </#{tag}>"

               expect(Dirt::Textify::Decoder.new(html).textify).to start_with '- A header -'
            end
         end
      end

      it 'should compress whitespace to one space' do
         html = "\n\nThis   is\treally\nspaced\ttext"

         expect(Dirt::Textify::Decoder.new(html).textify).to eq 'This is really spaced text'
      end

      it 'should replace all <br> tags with newlines' do
         html = 'Line one<br>Line two'

         expect(Dirt::Textify::Decoder.new(html).textify).to eq "Line one\nLine two"
      end

      it 'should replace paragraph end tags with double newlines' do
         html = '<p>I am a paragraph</p>'

         expect(Dirt::Textify::Decoder.new(html).textify).to eq "I am a paragraph\n\n"
      end

      # TODO: it should handle tables in a clean way.

      it 'should strip each line after processing' do
         html = "<div>  \n  <p>Some text</p><p>  \n  more text  \n  </p>  </div>"

         expect(Dirt::Textify::Decoder.new(html).textify).to eq "Some text\n\nmore text\n\n"
      end

      context 'tag removal' do
         it 'should remove style tags' do
            html = '<style>a {color: blue;}</style>'

            expect(Dirt::Textify::Decoder.new(html).textify).to eq ''
         end

         it 'should remove script tags' do
            html = '<script>someJsCode()</script>'

            expect(Dirt::Textify::Decoder.new(html).textify).to be_empty
         end

         it 'should remove all other html elements' do
            %w{div strong b i}.each do |tag|
               html = "<#{tag}></#{tag}>"

               expect(Dirt::Textify::Decoder.new(html).textify).to be_empty
            end
         end
      end
   end
end
