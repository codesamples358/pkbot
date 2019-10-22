module Pkbot::Kommersant::Html
  class ArticlePage < Pkbot::BackOffice::HtmlPage
    attr_accessor :contents, :date, :issue
    self.path  = "https://www.kommersant.ru/doc/:id"
    self.cache = true

    def pages
      @pages ||= @contents.css(".b-hiphop").map {|node| Page.new(node, self)}
    end

    def articles
      pages.flat_map &:articles
    end

    def date_db
      date.to_s(:db)
    end

    def article(kms_article)
      Article.new(self, kms_article)
    end

    def first_page
      pages.find {|page| page.first_page?}
    end

    def category(article)
      lookup_nodes(artilce).select {||}
    end

    def category_str(article)
    end
  end
end