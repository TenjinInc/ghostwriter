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
            doc.search('script').remove

            doc.search('a').each do |link_node|
               link_node.inner_html = "#{link_node.inner_html} (#{link_node['href']})"
            end

            doc.search('header, h1, h2, h3, h4, h5, h6').each do |node|
               node.inner_html = "#{node.inner_html}\n"
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
end