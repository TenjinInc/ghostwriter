# frozen_string_literal: true

module Ghostwriter
   class Writer
      def initialize(html)
         @source_html = html
      end

      # Intelligently strips HTML down to text.
      #
      # Options:
      #   link_base: the url to prefix relative links with
      def textify(options = {})
         html = @source_html.dup

         html.gsub!(/\n|\t/, ' ')
         html.squeeze!(' ')

         html.gsub!('</p>', "</p>\n\n")

         doc = Nokogiri::HTML(html)

         doc.search('style').remove
         doc.search('script').remove

         base = doc.search('base').first #<base> is unique by W3C spec

         base_url = base ? base['href'] : options[:link_base] || ''

         doc.search('a').each do |link_node|
            href = URI(link_node['href'])
            href = base_url + href.to_s unless href.absolute?

            link_node.inner_html = "#{link_node.inner_html} (#{href})"
         end

         doc.search('header, h1, h2, h3, h4, h5, h6').each do |node|
            node.inner_html = "- #{node.inner_html} -\n".squeeze(' ')
         end

         doc.search('hr').each do |node|
            node.replace "\n----------\n"
         end

         doc.search('br').each do |node|
            node.replace "\n"
         end

         # doc.search('p').each do |link_node|
         #   link_node.inner_html = link_node.inner_html + "\n\n"
         # end

         doc.text.gsub(/^[ ]+|[ ]+$/, '')
      end
   end
end
