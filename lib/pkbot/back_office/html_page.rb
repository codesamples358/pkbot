require 'nokogiri'
require 'rest_client'

module Pkbot::BackOffice
  class HtmlPage
    class_attribute :path
    class_attribute :paths
    class_attribute :cache
    class_attribute :caches
    class_attribute :disable_cache
    class_attribute :response_type

    self.cache = false
    self.disable_cache = false

    self.caches = {}

    attr_accessor :attrs

    def self.cache?(label)
      return false if self.disable_cache
      label.nil? ? self.cache : self.caches[label]
    end

    attr_accessor :files

    def initialize(*args)
      @attrs = args.extract_options!
      @files = {}
    end

    def doc(label = nil)
      @docs        ||= {}
      @docs[label] ||= Nokogiri::HTML::Document.parse html(label)
    end

    def html(label = nil)
      @htmls        ||= {}
      @htmls[label] ||= request_page(label)
    end

    def json(label = nil)
      text = html(label)
      text.starts_with?('"') ? text[1 .. -2] : JSON(text)
    end

    def request_page(label = nil, attrs = {})
      cached(label) || bo.body(bo.get_page(path(label, attrs), page_id(label)))
    end

    def cached(label)
      self.class.cache?(label) && bo.get_cached(page_id(label))
    end

    def page_id(label = nil)
      ([self.class.name.split('::')[-2, 2].join("_").underscore] + [label] +  @attrs.to_a).compact.join("_")
    end

    def post(*args)
      params = args.extract_options!
      label  = args.first
      
      request_params  = make_params.merge(params)
      options         = {params: request_params}

      bo.body bo.post_page(path(label, params), options, page_id(label))
    end

    def upload(label = nil, file_params)
      name, filename = file_params.first
      options        = {params: {name => File.open(filename, "r")}}

      bo.body bo.post_page(path(label, {}), options, page_id(label))
    end

    def post_json(label = nil, json)
      options = {
        request_headers: Http::CONTENT_JSON,
        request_body:    JSON(json)
      }

      bo.post_page(path(label), options, page_id(label))
    end

    def make_params
      params = {}

      @files.each do |name, path|
        params[name] = File.open(path, "r")  
      end

      params
    end

    def path(label = nil, attrs = {})
      path = label.nil? ? self.class.path : self.class.paths[label]

      path.dup.tap do |path|
        @attrs.merge(attrs).each do |key, value|
          path.gsub!(":#{key}", value.to_s)
        end
      end
    end

    def root
      doc.root
    end

    def [](xpath)
      doc.xpath xpath
    end

    def bo
      Pkbot::BackOffice
    end
  end
end

require_relative 'html_page/issues'
require_relative 'html_page/issue'
require_relative 'html_page/article'
require_relative 'html_page/articles_import'