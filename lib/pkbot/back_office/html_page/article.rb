module Pkbot::BackOffice
  class HtmlPage::Article < HtmlPage
    self.path = "/dept/8/press/187/year/#{Date.today.year}/issue/:issue_id/article/:id"

    self.paths = {
      :page       => '/api/content/article/:id/page',
      :publish    => '/api/article/:id/props/published/:published',
      :category   => '/api/content/article/:id/rubric/new',
      :save       => '/api/article/:id/content/save',
      :content    => '/api/article/:id/content/get',
      :categories => '/api/content/press/187/rubrics',
      :typograf   => '/api/article/typograf/2',
      :image      => '/api/upload/image/'
    }

    self.caches = {
      # :content => true
    }
  end
end