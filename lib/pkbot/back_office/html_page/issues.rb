module Pkbot::BackOffice
  class HtmlPage::Issues < HtmlPage
    self.path = "/api/content/issue/index/press/187/year/:year"
    self.cache = Pkbot::Location.development?

    def initialize(*)
      super
      @attrs[:year] ||= ($BO_YEAR || Date.today.year)
    end

    def issues
      @issues ||= json['control']['rows'].map {|row| Pkbot::BackOffice::Issue.new(row)}
    end
  end
end
