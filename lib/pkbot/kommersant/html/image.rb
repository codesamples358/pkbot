require 'fastimage'

module Pkbot::Kommersant::Html
  class Image
    attr_accessor :entry, :node

    # LINK_REGEX = /Issues.photo\/DAILY\/\d+\/\w+\/(.*)/
    FILENAME_REGEX = /([\w\.\-\_]*)$/
    PHOTO_PATH = "Issues.photo/DAILY"
    NODE_MAP   = {}

    class << self
      def for_node(node, *params)
        NODE_MAP[node] ||= new node, *params
      end

      def search(entry)
        entry.node.xpath(".//img[contains(@src, '#{PHOTO_PATH}')]").map do |node|
          self.for_node node, entry
        end.select {|image| (image.link_to_article? || image.entry_innermost?) && image.filename}
      end
    end

    def link_to_article?
      link && entry.article.article_ids.include?(link['href'][/doc\/(\d+)/, 1])
    end

    def entry_innermost?
      node.xpath("ancestor::article[1]").first == entry.node
    end

    def link
      node.xpath("ancestor::a[1]").first
    end

    def eql?(other)
      other.src == src
    end

    def ==(other)
      eql? other
    end

    def hash
      src.hash
    end

    def prefix?(prefix)
      src.include?("#{prefix.to_s.upcase}_")
    end

    def initialize(node, entry)
      @entry = entry
      @node  = node
    end

    def src
      node['src']
    end

    def filename
      src[FILENAME_REGEX, 1]
    end

    def save
      response = Pkbot::BackOffice.get_page(src)
      image_file.write response.body
    end

    def image_file
      entry.article.article.dir['images', filename].binary
    end

    def width
    end

    def height
    end

    def file
      save unless image_file.exists?
      image_file.to_s
    end

    def fast_image
      @fast_image ||= FastImage.new file
    end

    extend Forwardable
    def_delegators :fast_image, :size, :type
  end
end
