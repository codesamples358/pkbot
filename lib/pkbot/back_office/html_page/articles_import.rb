module Pkbot::BackOffice
  class HtmlPage::ArticlesImport < HtmlPage
    # http://bo.profkiosk.ru/api/content/issue/30315/article/import
    self.path = '/api/content/issue/:id/article/import'
    # self.path = '/api/article/import/:id/special/187'
  end
end