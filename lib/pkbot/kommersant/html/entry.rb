module Pkbot::Kommersant::Html
  class Entry
    attr_accessor :node, :issue, :article, :page, :article_id, :html_page
    include NodeEntity

    ARTICLE_MAP = {}

    def initialize(node, issue, article = nil, page = nil, article_id = nil, html_page = nil)
      @node       = node
      @issue      = issue
      @article    = article
      @page       = page
      @article_id = article_id
      @html_page  = html_page
    end

    def self.for(node, *args)
      ARTICLE_MAP[node] ||= Entry.new(node, *args)
    end

    def title
      @node.css('.article_name a').text
    end

    def page
      if node = @node.xpath("ancestor::div[contains(@class, 'b-hiphop')]").first
        Page.new(node, issue)
      end
    end

    def context?
      # node.name != 'article'
      additional_material?# || pager_link
    end

    def additional_material?
      !@node.xpath("ancestor::div[contains(@class, 'b-article__additional_materials')]").first.nil?
    end

    def pager_link
      @node.css("ul.b-pager .b-pager__page a").find {|link| link.text == '1'}
    end

    def context_for
      node = @node.xpath("ancestor::article[1]").first || pager_link && pager_link['href'][/doc\/(\d+)/, 1]

      if node
        Entry.for(node, issue)
      elsif pager_link
        article = issue.articles.find {|article| article.article_ids.include?(article_id)}
        article.entries.first
      end
    end

    def images
      @images ||= Image.search(self)
    end
  end
end