Snippet.add(:debug_image) do
  def itag
    ba.img_tag_for(ba.xml_article.html.biggest_image.file)
  end

  def file
    ba.xml_article.html.biggest_image.file
  end

  def ba
    Snippet[:main].ba
  end  
end
