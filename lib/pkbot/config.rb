require 'yaml'

class Pkbot::Config
  attr_accessor :issue

  def initialize(issue)
    @issue = issue
    read
  end

  def dir
    issue.issue_dir['config']
  end

  def main
    dir['config.yml']
  end

  def csv
    dir['config.csv']
  end

  def [](article)
    @configs ||= {}
    @configs[article] ||= Article.new(self, article)
  end

  def read
    if main.exists?
      YAML.load main.read
    end
  end

  def config
    @config ||= read || []
  end

  def write
    main.write config.to_yaml
  end

  def generate_from_xml
    config.clear

    @issue.articles.each do |article|
      self[article].generate
    end

    write
  end

  def csv_items
    @csv_items ||= csv.read.split("\n").reject{|line| line.strip.empty?}.map do |line|
      CsvItem.new(line, self)
    end
  end

  def xml?
    @issue.articles.any?
  end

  def generate_from_csv
    if !xml?
      puts "Отсутствует xml"
      return
    end
    
    config.clear

    csv_items.each do |item|
      config.push item.hash
    end

    found_articles = csv_items.map(&:article).compact

    (@issue.articles - found_articles).each do |article|
      config.push('title' => article.title, 'photo' => false, 'article_id' => article.id)
    end

    write
  end
end


require_relative 'config/article'
require_relative 'config/csv_item'