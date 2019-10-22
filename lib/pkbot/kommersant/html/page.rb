module Pkbot::Kommersant::Html
  class Page
    attr_accessor :issue, :node
    include NodeEntity

    MAPPING = {
      "первая полоса"    => 29583,
      "новости"          => 29586,
      "мировая политика" => 29730,
      "деловые новости"  => 29590,
      "культура"         => 29591,
      "спорт"            => 29592,
    }

    FIRST_PAGE = "первая полоса"

    def initialize(node, issue)
      @node  = node
      @issue = issue
    end

    def title
      @title ||= @node.css('h3.subtitle').text.gsub(/\t\r\n/, '').strip
    end

    TITLE_REGEX = /(.*)полоса №(\d+)/

    def category
      title[TITLE_REGEX, 1].try(:strip)
    end

    def bo_category
      MAPPING[category_l]
    end

    def page_no
      title[TITLE_REGEX, 2].try(:strip).to_i
    end

    def category_l # low-case
      category.mb_chars.downcase.to_s
    end

    def entries
      @articles ||= @node.css("article.b-hiphop__item").map {|node| Entry.new(node, issue, nil, self)}
    end

    def first?
      page_no == 1
    end
  end
end