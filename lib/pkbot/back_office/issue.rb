#encoding: utf-8

module Pkbot::BackOffice
  class Issue < Entity
    attr_accessor :row, :cols
    def initialize(row)
      @row = row
      @cols = row['cols']
    end

    ISSUE_LINK = /\/!\/content\/issue\/\d+\?tab=article/
    def number
      text = cols.find {|e| e['type'] == 'link' && e['href'] =~ ISSUE_LINK}['text']
      text[/№ ([\d]+(?:\/П)?)/, 1]
    end

    def valid?
      number
    end

    def id
      row['id']
    end

    DEFAULT_PARAMS = {
      "ParserId"            => "-1",
      "AutoAuthors"         => "true",
      "AutoRubrics"         => "true",
      "UseLastRubric"       => "true",
      "UsePageFromFileName" => "false"
    }

    def _import_file(filename)
      request = HtmlPage::ArticlesImport.new(id: id)
      request.files['upload'] = filename
      request.post(DEFAULT_PARAMS)
    end

    def import_articles(filename = kms_issue.file(:pxml))
      _import_file filename
    end

    def import_article(xml_id)
      article = kms_issue.articles.find {|article| article.id == xml_id}
      _import_file article.xml_file
    end

    def article_count
      page.article_count.try(:to_i)
    end

    def kms_issue
      Pkbot::Issue.for number.gsub("/П", 'p')
    end

    def articles
      @articles ||= page.json['data']['rows'].map {|row| Pkbot::BackOffice::Article.new(self, row)}
    end

    def reset_articles
      @page = nil
      @articles = nil
    end

    def article(id)
      articles.find {|article| article.id == id.to_s}
    end

    def page
      @page ||= HtmlPage::Issue.new(id: id)
    end

    def write_id_map
      map = {}

      articles.each_with_index do |article, index|
        kms_id = kms_issue.articles[index].id
        map[article.id] = kms_id
      end

      kms_issue.id_map_file.write map.to_json
    end

    def id_map
      kms_issue.id_map
    end

    def ensure_id_map
      id_map.all? do |id, kms_id|
        article(id).title == kms_issue.article(kms_id).title
      end
    end

    def process
      raise "Can't process non-empty issue; Delete all articles first" if article_count > 0
      import_articles
      reset_articles

      process2
    end

    def process2
      write_id_map

      articles.each {|article| no_ex {article.process}}
      articles.each {|article| no_ex {article.process_context}}
      articles.each {|article| no_ex {article.mark_for_deletion if article.trash?}}
    end

    def published?
      
    end

    def publish
      articles.each {|article| article.publish}
    end

    def unpublish
      articles.each {|article| article.unpublish}
    end

    class << self
      def issues_page
        # @issues_page ||= HtmlPage::Issues.new
        HtmlPage::Issues.new
      end

      def lookup(number)
        num_s = number.gsub(/p$/, '/П')
        issues_page.issues.find {|issue| issue.number == num_s}
      end
    end
  end
end
