module Pkbot::BackOffice
  class Entity
    
    attr_reader :node
    attr_reader :attributes

    def initialize(node, attributes = {})
      @node = node
      @attributes = attributes
    end

    def [](attr_name)
      attributes[attr_name]
    end

    def text
      @text ||= @node.to_s
    end
  end
end