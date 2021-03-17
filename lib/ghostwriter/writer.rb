# frozen_string_literal: true

module Ghostwriter
   # Main Ghostwriter converter object.
   class Writer
      def initialize(html)
         @source_html = html
      end

      # Strips HTML down to plain text.
      #
      # @param link_base the url to prefix relative links with
      def textify(link_base: '')
         html = normalize_whitespace(@source_html).gsub('</p>', "</p>\n\n")

         doc = Nokogiri::HTML(html)

         doc.search('style').remove
         doc.search('script').remove

         replace_anchors(doc, link_base)
         replace_headers(doc)

         simple_replace(doc, 'hr', "\n----------\n")
         simple_replace(doc, 'br', "\n")

         # doc.search('p').each do |link_node|
         #   link_node.inner_html = link_node.inner_html + "\n\n"
         # end

         # trim, but only single-space character
         doc.text.gsub(/^ +| +$/, '')
      end

      private

      def normalize_whitespace(html)
         html.gsub(/\s/, ' ').squeeze(' ')
      end

      def replace_anchors(doc, link_base)
         # <base> node is unique by W3C spec
         base     = doc.search('base').first
         base_url = base ? base['href'] : link_base

         doc.search('a').each do |link_node|
            href = URI(link_node['href'])
            href = base_url + href.to_s unless href.absolute?

            link_node.inner_html = "#{ link_node.inner_html } (#{ href })"
         end
      end

      def replace_headers(doc)
         doc.search('header, h1, h2, h3, h4, h5, h6').each do |node|
            node.inner_html = "- #{ node.inner_html } -\n".squeeze(' ')
         end
      end

      def simple_replace(doc, tag, replacement)
         doc.search(tag).each do |node|
            node.replace(replacement)
         end
      end
   end
end
