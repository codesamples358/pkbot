module Pkbot::Location
  extend self

  def development?
    File.expand_path(__FILE__).include?("/Users/shurik/Projects")
  end

  def path
    File.expand_path(__FILE__)
  end
end