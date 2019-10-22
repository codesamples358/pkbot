require 'nokogiri'

module Pkbot::BackOffice
  class Request
    class_attribute :path

    def initialize(*args)
      @attrs = args.extract_options!
    end

    def path
      self.class.path.dup.tap do |path|
        @attrs.each do |key, value|
          path.gsub!(":#{key}", value)
        end
      end
    end
  end
end