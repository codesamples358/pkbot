class FastImage
  def path
    instance_variable_get '@uri'
  end

  def width
    size[0]
  end

  def height
    size[1]
  end
end