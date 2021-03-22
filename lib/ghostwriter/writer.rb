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

         simple_replace(doc, '*[role="presentation"]', "\n")

         replace_anchors(doc, link_base)
         replace_headers(doc)
         replace_lists(doc)
         replace_tables(doc)

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
         base = get_link_base(doc, default: link_base)

         doc.search('a').each do |link_node|
            begin
               href = URI(link_node['href'])
               href = base + href.to_s unless href.absolute?
            rescue URI::InvalidURIError
               href = link_node['href'].gsub(/^(tel|mailto):/, '').strip
            end

            link_node.inner_html = if link_matches(href, link_node.inner_html)
                                      href.to_s
                                   else
                                      "#{ link_node.inner_html } (#{ href })"
                                   end
         end
      end

      def link_matches(first, second)
         first.to_s.gsub(%r{^https?://}, '').chomp('/') == second.gsub(%r{^https?://}, '').chomp('/')
      end

      def get_link_base(doc, default:)
         # <base> node is unique by W3C spec
         base_node = doc.search('base').first

         base_node ? base_node['href'] : default
      end

      def replace_headers(doc)
         doc.search('header, h1, h2, h3, h4, h5, h6').each do |node|
            node.inner_html = "-- #{ node.inner_html } --\n".squeeze(' ')
         end
      end

      def replace_lists(doc)
         doc.search('ul li').each do |node|
            node.inner_html = "- #{ node.inner_html }\n".squeeze(' ')
         end

         doc.search('ol').each do |list_node|
            list_node.search('./li').each_with_index do |list_item, i|
               list_item.inner_html = "#{ i + 1 }. #{ list_item.inner_html }\n".squeeze(' ')
            end
         end

         doc.search('ol, ul').each do |node|
            node.replace("\n#{ node.inner_html }\n")
         end
      end

      def replace_tables(doc)
         doc.css('table').each do |table|
            column_sizes = calculate_column_sizes(table)

            table.search('./thead/tr', './tbody/tr', './tr').each do |row|
               replace_table_nodes(row, column_sizes)

               row.inner_html = "#{ row.inner_html }|\n"
            end

            add_table_header_underline(table, column_sizes)

            table.inner_html = "#{ table.inner_html }\n"
         end
      end

      def calculate_column_sizes(table)
         column_sizes = table.search('tr').collect do |row|
            row.search('th', 'td').collect do |node|
               node.inner_html.length
            end
         end

         column_sizes.transpose.collect(&:max)
      end

      def add_table_header_underline(table, column_sizes)
         table.search('./thead').each do |row|
            header_bottom = "|#{ column_sizes.collect { |len| ('-' * (len + 2)) }.join('|') }|"

            row.inner_html = "#{ row.inner_html }#{ header_bottom }\n"
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
            node.replace(node.inner_html + replacement)
         end
      end
   end
end
