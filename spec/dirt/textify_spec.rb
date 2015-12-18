require 'spec_helper'

describe Dirt::Textify do
  it 'should have a version number' do
    expect(Dirt::Textify::VERSION).not_to be nil
  end

  it 'should remove style tags' do
    html = '<style>a {color: blue;}</style>'

    expect(Dirt::Textify.textify(html)).to eq ''
  end

  it 'should replace hr with a line of dashes' do
    html = '<hr>'

    expect(Dirt::Textify.textify(html)).to eq '----------'
  end

  it 'should make links visible within brackets' do
    html = '<a href="www.example.com">A link</a>'

    expect(Dirt::Textify.textify(html)).to include 'A link (www.example.com)'
  end

  it 'should add a newline after links' do
    html = '<a href="www.example.com">A link</a>'

    expect(Dirt::Textify.textify(html)).to end_with "\n"
  end

  it 'should compress whitespace to one space' do
    html = "\n\nThis   is\treally\nspaced\ttext"

    expect(Dirt::Textify.textify(html)).to eq 'This is really spaced text'
  end

  it 'should replace all <br> tags with newlines' do
    html = 'Line one<br>Line two'

    expect(Dirt::Textify.textify(html)).to eq "Line one\nLine two"
  end

  it 'should replace explicit paragraph end tags with double newlines' do
    html = '<p>I am a paragraph</p>'

    expect(Dirt::Textify.textify(html)).to eq "I am a paragraph\n\n"
  end

  it 'should remove all other html elements' do
    html = '<table></table><header></header><div></div>'

    expect(Dirt::Textify.textify(html)).to eq ''
  end
end
