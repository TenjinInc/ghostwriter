module Dirt
   module Textify
      class Decoder
         def initialize(html)
            @source_html = html
         end

         # Transmutes HTML into text.
         def textify
            html = @source_html.dup

            html.gsub!(/\n|\t/, ' ')
            html.squeeze!(' ')
            html.gsub!('</p>', "</p>\n\n")

            doc = Nokogiri::HTML(html)

            doc.search('style').remove

            doc.search('a').each do |link_node|
               link_node.inner_html = link_node.inner_html + ' (' + link_node['href'] + ")\n"
            end

            doc.search('hr').each do |link_node|
               link_node.replace '----------'
            end

            doc.search('br').each do |link_node|
               link_node.replace "\n"
            end

            # doc.search('p').each do |link_node|
            #   link_node.inner_html = link_node.inner_html + "\n\n"
            # end

            doc.text.gsub(/^[ ]+|[ ]+$/, '')
         end
      end
   end
end