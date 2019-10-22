module Pkbot::BackOffice
  class HtmlPage::Issue < HtmlPage
    # self.path = "/api/articles/list/:id"
    self.path = "/api/content/issue/:id/article/index"
    # http://bo.profkiosk.ru/api/content/issue/30315/article/index
    self.response_type = :json

    # self.cache = Pkbot::Location.development?
    self.cache = false

    def articles
      @articles ||= json['data']['rows'].map {|row| Pkbot::BackOffice::Article.new(self, row)}
    end

    def article_count
      articles.count
    end
  end
end