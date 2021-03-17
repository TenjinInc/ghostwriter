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
         replace_table(doc)

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

      def replace_table(doc)
         doc.css('table').each do |table|
            column_sizes = table.search('tr').collect do |row|
               row.search('th', 'td').collect do |node|
                  node.inner_html.length
               end
            end

            column_sizes = column_sizes.transpose.collect(&:max)

            table.search('./thead/tr', './tbody/tr', './tr').each do |row|
               replace_table_nodes(row, column_sizes)

               row.inner_html = "#{ row.inner_html }|\n"
            end

            table.search('./thead').each do |row|
               header_bottom = "|#{ column_sizes.collect { |len| ('-' * (len + 2)) }.join('|') }|"

               row.inner_html = "#{ row.inner_html }#{ header_bottom }\n"
            end

            table.inner_html = "#{ table.inner_html }\n"
         end
      end

      def replace_table_nodes(row, column_sizes)
         row.search('th', 'td').each_with_index do |node, i|
            new_content = "| #{ node.inner_html }".squeeze(' ')

            # +2 for the extra spacing between text and pipe
            node.inner_html = new_content.ljust(column_sizes[i] + 2)
         end
      end

      def simple_replace(doc, tag, replacement)
         doc.search(tag).each do |node|
            node.replace(replacement)
         end
      end
   end
end
