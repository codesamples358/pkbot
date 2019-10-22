module Pkbot::Kommersant::Html
  module NodeEntity
    def eql?(other)
      self.class == other.class && self.node == other.node
    end

    def ==(other)
      eql? other
    end

    def hash
      node.hash
    end
  end
end
