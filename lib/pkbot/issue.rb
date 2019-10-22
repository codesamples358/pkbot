#encoding: UTF-8

module Pkbot
  class Issue
    attr_accessor :number, :options
    delegate_keys :options, :issue_path, :clear_dir, :bo_number

    def initialize(*args)
      @options = args.extract_options!
      @number = args[0].to_s

      issue_dir.clear! if clear_dir
      image_dir # make
      config_dir
    end

    ISSUE_MAP = {}
    def self.for(*args)
      number = args[0]
      ISSUE_MAP[number.to_s] ||= new(*args)
    end

    def issue_dir
      @issue_dir ||= Folder['issues', issue_path || @number]
    end

    def number_path
      @number_path ||= @number.to_s
    end

    def image_dir
      issue_dir['images']
    end

    def config_dir
      issue_dir['config']
    end

    def dir(type)
      issue_dir[type.to_s]
    end

    def file(type)
      dir = dir(type)
      filename = Dir.new(dir).entries.find {|file| !Dir.exists?(file)}
      dir[filename] if filename
    end

    def filename(type)
      File.basename file(type)
    end

    EXT = {
      :pxml => 'xml'
    }

    NAME = {
      :pxml => ->(issue) { issue.filename(:xml) }
    }

    def new_file(type, ext = EXT[type])
      filename = NAME[type] ? NAME[type][self] : "#{@number}.#{ext}"
      dir(type)[filename]
    end

    def file_exists?(type)
      !file(type).nil?
    end

    def download(force = false)
      [:xml, :pdf].select do |type|
        Kommersant::Ftp.download(type, @number, dir(type)) if !file_exists?(type) || force
      end
    end

    def downloaded?
      [:xml, :pdf].all? {|type| file_exists?(type)}
    end

    def download_process
      download
      process_xml
    end

    def processed?
      file_exists?(:pxml)
    end

    SUBS = {
      ",--" => ", -",
      ".--" => ". -",
      ",—"  => ", —",
      "&quot;" => '"',
      "windows-1251" => "UTF-8"
    }

    def xml_utf8
      File.open(file(:xml), "r:Windows-1251:UTF-8")
    end

    def process_xml
      return unless file_exists?(:xml)
      
      text = xml_utf8.read
      SUBS.each {|old, _new| text.gsub! old, _new }

      File.open(new_file(:pxml), "w:UTF-8") {|pxml| pxml.write text}
    end

    def process_parsed_xml(text)
      doc = xml_doc(text)
      doc.to_s
    end

    def xml_doc(text = xml_utf8)
      Nokogiri::XML::Document.parse text, "UTF-8"
    end

    def doc(type = :pxml)
      return nil unless file(type)
      type == :xml ? xml_doc : xml_doc(File.open(file(:pxml), "r"))
    end

    def articles(type = :pxml)
      @_articles       ||= {}
      @_articles[type] ||= doc(type) ? doc(type).xpath("//item").map {|item| Pkbot::Article.new(item, self)} : []
    end

    def article(id)
      articles.find {|article| article.id == id}
    end

    def xml_only(article, type = :pxml)
      issue_dir['articles', article.id, "#{article.id}.xml"].write(doc.to_s)
    end

    def date_out
      Date.parse doc.xpath("//dateout").first.text
    end

    def html
      @html ||= Kommersant::Html::Issue.new(self)
    end

    def id_map_file
      issue_dir['id_map.json']
    end

    def id_map
      JSON(id_map_file.read) if id_map_file.exists?
    end

    def bo_issue
      @bo_issue ||= Pkbot::BackOffice::Issue.lookup(number)   
    end

    def undefined_articles
      articles.select {|article| article.html.entries.empty?}.reject(&:trash?)
    end

    def detect_difficult_contexts
      return true if undefined_articles.empty?

      possible_contexts = undefined_articles.dup
      
      # TODO: tried to detect context by downloading ITS PAGE. failed due to multiple-articles case
      # possible_contexts.each {|article| article.html.load_pages}

      articles.each do |article| 
        article.html.load_pages
        break if undefined_articles.empty?
      end

      if possible_contexts.all?(&:context?)
        true
      else
        # TODO: if such cases occur - load & parse all pages
      end
    end

    def config
      @config ||= Config.new(self)
    end

    def process
      download
      process_xml

      detect_difficult_contexts
      bo_issue.process
    end

    def pdf
      Kommersant::Pdf.new(self)
    end

    def publish
      bo_issue.publish
    end

    def unpublish
      bo_issue.unpublish
    end

    def extract_pdf_text(max_page)
      (1 .. [pdf.reader.pages.size, max_page].min).each do |page|
        issue_dir['pdf_text', "#{page}.txt"].write pdf.reader.page(page).text
      end
    end
  end
end