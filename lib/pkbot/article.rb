module Pkbot
  class Article
    attr_accessor :node, :issue

    def initialize(node, issue)
      @node = node
      @issue = issue
    end

    def id
      @node.xpath('ID').text
    end

    def title
      @node.xpath('title').first.text
    end

    def page
      el = @node.xpath('page').first
      el && el.text.to_i
    end

    def xml_file_
      dir["#{id}.xml"]
    end

    def dir
      issue.issue_dir['articles', id]
    end

    def xml_file
      unless File.exists?(xml_file_)
        doc     = issue.doc(:pxml)
        channel = doc.xpath("//channel").first
        all     = channel.children 

        channel.xpath('item').each do |node| 
          if Pkbot::Article.new(node, issue).id != id
            node.remove
          end
        end

        xml_file_.write(doc.to_s)

      end

      xml_file_
    end

    def import
    end

    def html
      issue.html.articles.find {|article| article.article == self}
    end

    def category_id
      page == 1 ? 29583 : html.pages.first.try(:bo_category)
    end

    def category_str
      Pkbot::Kommersant::Html::Page::MAPPING.invert[category_id]
    end

    def context?
      html.context?
    end

    def context_for
      if context?
        html.context_for.article
        # issue.articles.find {|a| a.html.entries.any? {|entry| entry == html.context_entry.context_for}}
      end
    end

    def id_map
      issue.id_map.try(:invert)
    end

    def bo_article
      @bo_article ||= if id_map
        issue.bo_issue.article(id_map[id])
      end
    end

    def trash?
      page == 1 && (title == 'Новости' || title == 'Главные новости') || 
        title.include?("Индексы ведущих фондовых бирж")
    end

    def make_indicators?
      title.include?("Официальные курсы")
    end

    def config
      issue.config[self]
    end

    def infog
      @infog ||= Array(config.infog).map do |path| 
        abs_path = issue.image_dir.expand path
        FastImage.new abs_path
      end
    end
  end
end