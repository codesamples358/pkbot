class Pkbot::Config
  class Article
    OPTIONS = %w(photo infog page category title image_map article_id deleted csv_title xml_title)
    attr_accessor :article, :config, :issue_config

    delegate_keys :config, OPTIONS

    def initialize(issue_config, article)
      @issue_config = issue_config
      @article      = article
    end

    def config
      @config ||= find_node || push_new
    end

    def push_new
      {}.tap {|n| @issue_config.config.push n}
    end

    def find_node
      @issue_config.config.find do |config_node|
        config_node['article_id'] == @article.id || config_node['title'] == @article.title
      end
    end

    def generate
      self.title      = article.title
      self.article_id = article.id
      self.photo      = false
    end
  end
end
