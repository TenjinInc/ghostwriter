require 'spec_helper'

describe Dirt::Textify::Decoder do
   describe '#textify' do
      it 'should remove style tags' do
         html = '<style>a {color: blue;}</style>'

         expect(Dirt::Textify::Decoder.new(html).textify).to eq ''
      end

      it 'should replace hr with a line of dashes' do
         html = '<hr>'

         expect(Dirt::Textify::Decoder.new(html).textify).to eq '----------'
      end

      it 'should make links visible within brackets' do
         html = '<a href="www.example.com">A link</a>'

         expect(Dirt::Textify::Decoder.new(html).textify).to include 'A link (www.example.com)'
      end

      it 'should add a newline after links' do
         html = '<a href="www.example.com">A link</a>'

         expect(Dirt::Textify::Decoder.new(html).textify).to end_with "\n"
      end

      it 'should compress whitespace to one space' do
         html = "\n\nThis   is\treally\nspaced\ttext"

         expect(Dirt::Textify::Decoder.new(html).textify).to eq 'This is really spaced text'
      end

      it 'should replace all <br> tags with newlines' do
         html = 'Line one<br>Line two'

         expect(Dirt::Textify::Decoder.new(html).textify).to eq "Line one\nLine two"
      end

      it 'should replace explicit paragraph end tags with double newlines' do
         html = '<p>I am a paragraph</p>'

         expect(Dirt::Textify::Decoder.new(html).textify).to eq "I am a paragraph\n\n"
      end

      # TODO: it should handle tables in a clean way.

      it 'should remove all other html elements' do
         html = '<header></header><div></div>'

         expect(Dirt::Textify::Decoder.new(html).textify).to eq ''
      end

      it 'should strip each line after processing' do
         html = "<div>  \n  <p>Some text</p><p>  \n  more text  \n  </p>  </div>"

         expect(Dirt::Textify::Decoder.new(html).textify).to eq "Some text\n\nmore text\n\n"
      end

      it 'should remove script tags'
   end
end
