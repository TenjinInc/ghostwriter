# frozen_string_literal: true

module Ghostwriter
   # Main Ghostwriter converter object.
   class Writer
      attr_reader :link_base, :ul_marker, :ol_marker, :table_row, :table_column, :table_corner

      # Creates a new ghostwriter
      #
      # @param [String] link_base the url to prefix relative links with
      def initialize(link_base: '', ul_marker: '-', ol_marker: '1',
                     table_column: '|', table_row: '-', table_corner: '|')
         @link_base    = link_base
         @ul_marker    = ul_marker
         @ol_marker    = ol_marker
         @table_column = table_column
         @table_row    = table_row
         @table_corner = table_corner

         freeze
      end

      # Strips HTML down to plain text.
      #
      # @param html [String] the HTML to be convert to text
      #
      # @return converted text
      def textify(html)
         doc = Nokogiri::HTML(html.gsub(/\s+/, ' '))

         doc.search('style, script').remove

         replace_anchors(doc)
         replace_images(doc)

         simple_replace(doc, '*[role="presentation"]', "\n")

         replace_headers(doc)
         replace_lists(doc)
         replace_tables(doc)

         simple_replace(doc, 'hr', "\n----------\n\n")
         simple_replace(doc, 'br', "\n")
         simple_replace(doc, 'p', "\n\n")

         normalize_lines(doc)
      end

      private

      def normalize_lines(doc)
         doc.text.strip.split("\n").collect(&:strip).join("\n").concat("\n")
      end

      def replace_anchors(doc)
         doc.search('a').each do |link_node|
            href = get_link_target(link_node, get_link_base(doc))

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

      def get_link_base(doc)
         # <base> node is unique by W3C spec
         base_node = doc.search('base').first

         base_node ? base_node['href'] : @link_base
      end

      def get_link_target(link_node, base)
         href = URI(link_node['href'])
         if href.absolute?
            href
         else
            base + href.to_s
         end
      rescue URI::InvalidURIError
         link_node['href'].gsub(/^(tel|mailto):/, '').strip
      end

      def replace_headers(doc)
         doc.search('header, h1, h2, h3, h4, h5, h6').each do |node|
            node.inner_html = "-- #{ node.inner_html } --\n".squeeze(' ')
         end
      end

      def replace_images(doc)
         doc.search('img[role=presentation]').remove

         doc.search('img').each do |img_node|
            src = img_node['src']
            alt = img_node['alt']

            src = 'embedded' if src.start_with? 'data:'

            img_node.replace("#{ alt } (#{ src })") unless alt.nil? || alt.empty?
         end
      end

      def replace_lists(doc)
         doc.search('ol').each do |list_node|
            replace_list_items(list_node, @ol_marker, after_marker: '.', increment: true)
         end

         doc.search('ul').each do |list_node|
            replace_list_items(list_node, @ul_marker)
         end

         doc.search('ul, ol').each do |list_node|
            list_node.replace("#{ list_node.inner_html }\n")
         end
      end

      def replace_list_items(list_node, marker, after_marker: '', increment: false)
         list_node.search('./li').each do |list_item|
            list_item.replace("#{ marker }#{ after_marker } #{ list_item.inner_html }\n")

            marker = marker.next if increment
         end
      end

      def replace_tables(doc)
         doc.css('table').each do |table|
            # remove whitespace between nodes
            table.search('//text()[normalize-space()=""]').remove

            column_sizes = calculate_column_sizes(table)

            table.search('./thead/tr', './tbody/tr', './tr').each do |row|
               replace_table_nodes(row, column_sizes)

               row.replace("#{ row.inner_html }#{ @table_column }\n")
            end

            add_table_header_underline(table, column_sizes)

            table.replace("\n#{ table.inner_html }\n")
         end
      end

      def calculate_column_sizes(table)
         column_sizes = table.search('tr').collect do |row|
            row.search('th', 'td').collect do |node|
               node.text.length
            end
         end

         column_sizes.transpose.collect(&:max)
      end

      def add_table_header_underline(table, column_sizes)
         table.search('./thead').each do |thead|
            lines         = column_sizes.collect { |len| @table_row * (len + 2) }
            underline_row = "#{ table_corner }#{ lines.join(@table_corner) }#{ @table_corner }"

            thead.replace("#{ thead.inner_html }#{ underline_row }\n")
         end
      end

      def replace_table_nodes(row, column_sizes)
         row.search('th', 'td').each_with_index do |node, i|
            new_content = node.text.ljust(column_sizes[i] + 1)

            node.replace("#{ @table_column } #{ new_content }")
         end
      end

      def simple_replace(doc, tag, replacement)
         doc.search(tag).each do |node|
            node.replace(node.inner_html + replacement)
         end
      end
   end
end
