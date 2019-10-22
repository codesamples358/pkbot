# encoding: utf-8

class Pkbot::Config
  class CsvItem
    attr_accessor :line, :title, :photo, :infog
    def initialize(line, config)
      @config = config
      @title, @photo, @infog = cut line, ';'

      @photo = cut @photo, ','
      @infog = cut @infog, ','

      @line = line
    end

    def hash
      hash = {
        'csv_title' => title, 
        'photo'     => photo && photo[0] == '1',
      }

      hash['infog'] = infog if infog.any?

      if articles.any?
        hash['article_id'] = article.try(:id) || '<<NOT FOUND>>'
        hash['xml_title']  = article.try(:title) if article
      end

      hash
    end

    def articles
      @config.issue.articles
    end

    def article
      @article ||= find(:match?) || find(:match_words?) || indicator_article
    end

    def indicator_article
      words(title) == ['индикаторы'] && articles.find {|article| article.make_indicators?}
    end

    def find(method_name)
      articles.find {|article| send(method_name, article)}
    end

    def match?(article)
      title == article.title
    end

    def match_words?(article)
      words(title) == words(article.title)
    end

    def words(string)
      string.scan(/\p{L}+/).map{|w| w.mb_chars.downcase.gsub('ё', 'е').to_s}
    end

    def cut(piece, delim)
      piece ? piece.split(delim).map(&:strip) : []
    end
  end
end
