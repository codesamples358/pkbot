require 'open-uri'

module Pkbot::Kommersant::Html
  class Issue < Pkbot::BackOffice::HtmlPage
    attr_accessor :contents, :date, :issue
    self.path  = "https://www.kommersant.ru/daily/:date_db"
    self.cache = true

    def initialize(issue)
      @issue    = issue
      @date     = issue.date_out
      super(date_db: date_db)
      @contents = doc.css("div.b-gazeta").select {|node| node.css('.b-hiphop').size > 1}.first
    end

    def pages_to_search
      @pages_to_search ||= [self]
    end

    def pages
      @pages ||= @contents.css(".b-hiphop").map {|node| Page.new(node, self)}
    end

    def date_db
      date.to_s(:db)
    end

    def article(kms_article)
      issue.articles.find {|article| article.article == kms_article}
    end

    def articles
      @articles ||= issue.articles.map {|article| Article.new(self, article)}
    end

    def load_article_pages
      articles.each(&:load_pages)
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