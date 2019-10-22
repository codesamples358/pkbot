module Pkbot::Kommersant::Html
  class Article
    attr_accessor :article, :issue

    def initialize(issue, article)
      @article = article
      @issue   = issue
    end

    def entry
      by_id.first || by_title.first
    end

    def entries(search_all = true)
      @page_entries ||= {}
      pages = search_all ? issue.pages_to_search : [issue]

      on_pages = pages.flat_map do |html_page|
        @page_entries[html_page] ||= (by_id(html_page).to_a + by_title(html_page).to_a).uniq
      end 

      (on_pages + main_entries).uniq
    end

    def html_pages
      @html_pages ||= article_ids.map do |article_id|
        ArticlePage.new(id: article_id)
      end
    end

    def article_ids
      entries(false).map(&:article_id).push(article.id).uniq
    end

    def main_entries
      @main_entries ||= []
    end

    def load_pages
      get_pages
      issue.pages_to_search.push *html_pages
    end

    def get_pages
      html_pages.each do |page|
        main = page.doc.css('.col-big article').first
        main_entries.push Entry.for(main, issue, self, nil, page.attrs[:id], page)
      end
    end

    def node_entry(link_node, html_page)
      article_id   = link_node['href'][/doc\/(\d+)/, 1]
      article_node = link_node.ancestors('article')[0]
      return nil unless article_node
      entry = Entry.for(article_node, issue, self, nil, article_id, html_page)
      return nil if entry.article && entry.article != self
      entry
    end

    def by_id(html_page)
      html_page["//a[contains(@href, '/doc/#{article.id}')]"].map {|link_node| node_entry(link_node, html_page)}.compact
      # issue["//a[contains(@href, '/doc/#{article.id}')]/ancestor::article[1]"].map {|node| Entry.new(node, issue, self)}
    end

    def escaped_title
      parts = ['']

      article.title.chars.each do |symbol|
        if %w(' ").include?(symbol)
          parts += [symbol, '']
        else
          parts.last << symbol
        end
      end

      parts
    end

    def escaped_dbl_quote
      article.title.gsub('"', '\"')
    end

    module ArticleLinks
      def article_links
        @article_links ||= self["//a[contains(@href, '/doc/')]"].to_a
      end

      def article_links_containing(text)
        article_links.select {|node| node.text.include?(text)}
      end
    end

    def by_title(html_page)
      # html_page["//a[contains(@href, '/doc/') and contains(., '#{escaped_title}')]"].map {|link_node| node_entry(link_node, html_page)}.compact
      html_page.extend(ArticleLinks)
      html_page.article_links_containing(article.title).map {|link_node| node_entry(link_node, html_page)}.compact
    end

    def first_page?
      pages.any? {|page| page.first?}
    end

    def context?
      entries.any?(&:context?)
    end

    def context_entry
      entries.find(&:context?)
    end

    def context_for
      context_entry.context_for.article
    end

    def pages
      entries.map(&:page).compact
    end

    def images
      get_pages if main_entries.empty?
      @images ||= entries.flat_map {|entry| entry.images}.uniq
    end

    def biggest_image
      images.sort_by{|image| image.size[0]}.last
    end
  end
end