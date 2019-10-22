module Pkbot::BackOffice
  class Article
    
    attr_accessor :issue, :row

    def initialize(issue, row)
      @issue = issue
      @row   = row
    end

    def id
      row['id'].to_s
    end

    def title
      # row['cols'].find {|e| e['type'] == 'link'}['text']
      col = row['cols'].find {|e| e['type'] == 'link' || e['type'] == 'link2'} || row['cols'].find {|e| e['href'] && e['href'].include?(id)}
      col['text']
    end

    def tds
      node.xpath('td')
    end

    def html_page
      HtmlPage::Article.new id: id
    end

    def page=(value)
      html_page.post_json(:page, value: value)
    end

    def category=(value)
      html_page.post_json(:category, value: value)
    end

    def publish
      html_page.post(:publish, published: true) unless config.deleted
    end

    def unpublish
      html_page.post(:publish, published: false)
    end

    def typograf
      ts = Time.now.to_i
      save_as("typograf_#{ts}_before")
      prep = preprocess body
      enc  = encode_for_typograf(prep)
      save_as("typograf_#{ts}_prep", prep)
      save_as("typograf_#{ts}_encoded", enc)

      # json_response = html_page.post(:typograf, '' => enc)#.gsub(/(\<br\>)*/, "&nbsp;\n"))

      # artlebedev, post json:
      json_response = html_page.post_json(:typograf, {'value' => enc})
      
      # processed = JSON('[' + json_response + ']')[0]
      processed = JSON('[' + json_response.body.force_encoding("UTF-8") + ']')[0]

      @body  = postprocess(processed)
      save_as("typograf_#{ts}_after")
    end

    # NO_ENC = "!$&'()*+,-./0123456789:;=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]_abcdefghijklmnopqrstuvwxyz~"  # default
    # NO_ENC = "!$&'()*+,-./0123456789:;=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]_abcdefghijklmnopqrstuvwxyz~"

    # ENC = "\x00\x01\x02\x03\x04\x05\x06\a\b\t\n\v\f\r\x0E\x0F\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1A\e\x1C\x1D\x1E\x1F \"#%<>\\^`{|}\x7F\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E\x8F\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F\xA0\xA1\xA2\xA3\xA4\xA5\xA6\xA7\xA8\xA9\xAA\xAB\xAC\xAD\xAE\xAF\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9\xBA\xBB\xBC\xBD\xBE\xBF\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF="

    def encode_for_typograf(string)
      # weird obsolete %uXXXX ECMA encoding; TODO: rewrite using some library
      replace_unicode = string.chars.map do |char| 
        cp = char.codepoints[0]
        if  cp > 255
          "%u" + ("%4s" % cp.to_s(16).upcase).gsub(' ', '0')
        else
          URI.encode URI.encode(char), "< =\">\n&;(),:?" 
        end
      end.join
    end

    def replace_quotes
      string = content_title.dup
      indices = content_title.mb_chars.chars.each_index.select {|i| string[i] == '"'}
      return unless indices.size % 2 == 0

      indices.each.with_index do |i, j|
        string[i] = '«' if j % 2 == 0
        string[i] = '»' if j % 2 == 1
      end

      @title = string
    end

    def typograf!
      typograf
      save
    end

    def content_json
      @json_content ||= JSON html_page.html(:content)
    end

    def content_body
      content_json["body"]
    end

    def content_title
      @title ||= content_json["title"]
    end

    def reset_content
      @title        = nil
      @body         = nil
      @json_content = nil
    end

    attr_writer :title, :body

    # def title
    #   @title ||= content_title
    # end

    def body
      @body  ||= content_body
    end

    def save
      prep      = preprocess body
      encoded64 = Base64.encode64(prep).gsub("\n", "")

      json = { 'title' => content_title, 'body' => encoded64 } # , 'picsReadingTimes' => 1, 'styled' => 0 }
      saved = html_page.post_json(:save, json)
      reset_content
      saved
    end

    ARTICLES_DIR = Pkbot::Folder.tmp['articles']

    def save_file(name)
      ARTICLES_DIR[xml_article.id, "#{name}.txt"]
    end

    def save_as(name, text = nil)
      if Pkbot::Location.development?
        save_file(name).write(text || body)
      end
    end

    def assert_equal(name)
      version(name) == body
    end

    def revert_to(name)
      @body = version(name)
      save
    end

    def version(name)
      save_file(name).read
    end

    def preprocess(text)
      text.gsub(/(\<br\>)+/, '&nbsp;')
    end

    ENTITY_CODES = {
      34=>"quot", 38=>"amp", 60=>"lt", 62=>"gt", 128=>"euro", 130=>"sbquo", 131=>"fnof", 132=>"bdquo", 133=>"hellip", 
      134=>"dagger", 135=>"Dagger", 136=>"circ", 137=>"permil", 138=>"Scaron", 139=>"lsaquo", 140=>"OElig", 142=>"Zcaron", 
      145=>"lsquo", 146=>"rsquo", 147=>"ldquo", 148=>"rdquo", 149=>"bull", 150=>"ndash", 151=>"mdash", 152=>"tilde", 
      153=>"trade", 154=>"scaron", 155=>"rsaquo", 156=>"oelig", 158=>"zcaron", 159=>"Yuml", 0=>"no", 161=>"iexcl", 
      162=>"cent", 163=>"pound", 164=>"curren", 165=>"yen", 166=>"brvbar", 167=>"sect", 168=>"uml", 169=>"copy", 
      170=>"ordf", 171=>"laquo", 172=>"not", 173=>"shy", 174=>"reg", 175=>"macr", 176=>"deg", 177=>"plusmn", 178=>"sup2", 
      179=>"sup3", 180=>"acute", 181=>"micro", 182=>"para", 183=>"middot", 184=>"cedil", 185=>"sup1", 186=>"ordm", 
      187=>"raquo", 188=>"frac14", 189=>"frac12", 190=>"frac34", 191=>"iquest", 192=>"Agrave", 193=>"Aacute", 
      194=>"Acirc", 195=>"Atilde", 196=>"Auml", 197=>"Aring", 198=>"AElig", 199=>"Ccedil", 200=>"Egrave", 201=>"Eacute", 
      202=>"Ecirc", 203=>"Euml", 204=>"Igrave", 205=>"Iacute", 206=>"Icirc", 207=>"Iuml", 208=>"ETH", 209=>"Ntilde", 
      210=>"Ograve", 211=>"Oacute", 212=>"Ocirc", 213=>"Otilde", 214=>"Ouml", 215=>"times", 216=>"Oslash", 217=>"Ugrave", 
      218=>"Uacute", 219=>"Ucirc", 220=>"Uuml", 221=>"Yacute", 222=>"THORN", 223=>"szlig", 224=>"agrave", 225=>"aacute", 
      226=>"acirc", 227=>"atilde", 228=>"auml", 229=>"aring", 230=>"aelig", 231=>"ccedil", 232=>"egrave", 233=>"eacute", 
      234=>"ecirc", 235=>"euml", 236=>"igrave", 237=>"iacute", 238=>"icirc", 239=>"iuml", 240=>"eth", 241=>"ntilde", 
      242=>"ograve", 243=>"oacute", 244=>"ocirc", 245=>"otilde", 246=>"ouml", 247=>"divide", 248=>"oslash", 249=>"ugrave", 
      250=>"uacute", 251=>"ucirc", 252=>"uuml", 253=>"yacute", 254=>"thorn", 255=>"yuml"
    }

    def postprocess(text)
      text.gsub(/\&\#(\d+)\;/) do |md|
        name = ENTITY_CODES[$1.to_i]
        "&#{name};"
      end
    end

    def kms_issue
      issue.kms_issue
    end

    def doc
      @doc ||= Nokogiri::HTML(content_body)
    end

    def body_node
      doc.at_css("body")
    end

    def context_html
      @doc = nil
      intro = body_node.children.first

      h2 = Nokogiri::XML::Node.new "h2", doc
      h2.content = intro['bo-el'] == 'intro' ? intro.text : "Контекст"
      intro.add_previous_sibling h2

      div = Nokogiri::XML::Node.new "div", doc
      div['bo-el'] = 'strongp'
      div.content  = content_title

      if intro['bo-el'] == 'intro'
        intro.add_next_sibling div
        intro.remove
      else
        intro.add_previous_sibling div
      end

      body_node.inner_html
    end

    def process_context
      if xml_article.context?
        xml_article.context_for.bo_article.add_as_context(self)
        mark_for_deletion
      end
    end

    def add_as_context(article)
      @body = body + "\n" + article.context_html
      save
    end

    def insert_image(image = xml_article.html.biggest_image)
      img = img_tag_for image.file

      if (existing_img = intro.next_sibling.css('img').first)
        div = existing_img.parent
        existing_img.remove
        div.add_child img
      else
        intro.add_next_sibling img
      end

      save_html
    end

    def intro
      body_node.children.first
    end

    def author
      body_node.children.last
    end

    def text_blocks
      body_node.xpath("div[not(@bo-el)]")
    end

    def block_at(ratio)
      sizes = text_blocks.map {|block| block.text.size}
      total = sizes.sum
      i     = 1
      i += 1 while sizes[0, i].sum.to_f / total < ratio
      text_blocks[i - 1]
    end

    def save_html
      @body = body_node.inner_html
      save
    end

    DEFAULT_IMG_CSS = {width: '100%'}

    def img_tag_for(local_path, css = DEFAULT_IMG_CSS)
      img_tag bo_image(local_path), css
    end

    def bo_image(local_path)
      config.image_map ||= {}

      if stored = config.image_map[local_path]
        stored
      else 
        json  = html_page.upload(:image, upload: local_path)
        bo_id = json[1 .. -2]
        config.image_map[local_path] = bo_id
        config.issue_config.write
        bo_id
      end
    end

    def upload_image
      json = html_page.upload(:image, upload: local_path)
      json[1 .. -2]
    end

    def img_tag(bo_file, css = DEFAULT_IMG_CSS)
      Nokogiri::XML::Node.new("img", doc).tap do |img|
        css_str = css.map{|k, v| "#{k}: #{v};"}.join

        img['imgid'] = bo_file
        img['src']   = "http://e.profkiosk.ru/service_tbn2/#{bo_file}"
        img['style'] = css_str
      end
    end

    LEFT_INFOG_STYLE  = {'width' => '40%', 'float' => 'left', 'margin-bottom' => '20px', 'margin-right' => '20px'}
    RIGHT_INFOG_STYLE = {'width' => '40%', 'float' => 'right', 'margin-bottom' => '20px', 'margin-left' => '20px'}

    def insert_infog
      return unless infog.any?
      styles = [LEFT_INFOG_STYLE, RIGHT_INFOG_STYLE]

      if infog.size == 1 && infog.first.width > 750
        author.add_previous_sibling img_tag_for(infog.first.path)
      else
        k = 1.0 / (infog.size + 1)

        infog.each_with_index do |img, i|
          block_at(k * (i + 1)).children.first.add_previous_sibling(
            img_tag_for(img.path, styles[i % 2])
          )
        end
      end

      save_html
    end

    def infog
      xml_article.infog
    end

    def id_map
      issue.id_map
    end    

    def xml_article
      if id_map
        kms_issue.article(id_map[id])
      else
        # @xml_article ||= kms_issue.articles.find {|item| item.title == title}
      end
    end

    def mark_for_deletion
      config.deleted = true
      config.issue_config.write
      self.page = 100
    end

    def config
      xml_article.config
    end

    def trash?
      xml_article.trash?
    end

    def process_indicators
      if title.include?("Официальные курсы")
        @title = "Индикаторы"
        # @body  = "" # backoffice validation fails

        save
      end
    end

    def process
      no_ex('QUOTES')     { replace_quotes     }
      no_ex('TYPOGRAF')   { typograf!          }
      no_ex('INDICATORS') { process_indicators }

      no_ex('PAGE')       { set_page     }
      no_ex('CATEGORY')   { set_category }

      no_ex('IMAGE')      { insert_image if config.photo }
      no_ex('INFOG')      { insert_infog if config.infog }
    end

    def set_category
      self.category = xml_article.category_id
    end

    def set_page
      self.page     = xml_article.page
    end

    def no_ex(stage, &block)
      super("[ARTICLE: #{xml_article.title}][#{stage}]", &block)
    end
  end
end
