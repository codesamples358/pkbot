require 'net/http/post/multipart'
require 'http-cookie'

module Pkbot::BackOffice
  module Http
    FAKE_HEADERS = {
      "User-Agent"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv", 
      # "Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", 
      "Accept" => "*/*",
      "Accept-Language"=>"en-US,en;q=0.5", 
      "Accept-Encoding"=>"gzip, deflate",
      "Connection"=>"keep-alive",
      # "X-NewRelic-ID" => "XAQFUFNWGwIBXFNbAQYG"
    } 

    def http(uri)
      http         = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == 'https'
        puts "Using SSL..."
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      http.read_timeout = 500
      http
    end

    def add_headers(request, headers = {})
      FAKE_HEADERS.merge(headers || {}).each {|name, value| request[name] = value}
    end

    def add_body(request, body)
      return unless body
      request.body = body
    end

    def add_cookies(request, uri, additional_cookies = [])
      if cookie_jar.cookies(uri).any?
        request['Cookie'] = HTTP::Cookie.cookie_value(cookie_jar.cookies(uri))
      end
    end

    def uri(url)
      url = "http://#{HOST}#{url}" if url.starts_with?('/')
      URI(url)
    end

    Unauthorized    = Class.new StandardError
    BackOfficeError = Class.new StandardError

    def check_login(response)
      raise Unauthorized if response['location'] && response['location'].include?("ShortLogin")
      response
    end

    def check_500(response)
      raise BackOfficeError if response.code.to_i == 500 && !$DISABLE_NO_EX
      response
    end

    def get_page(url, filename = nil, options = {})
      handling_exceptions do
        login_if_needed
        get(url, filename, options)
      end
    end

    def handling_exceptions(&request_block)
      count    ||= 0
      response = yield
      check_login response
      check_500   response
    rescue Unauthorized
      relogin
      retry
    rescue BackOfficeError
      puts "Retrying 500.. [#{count}]"
      count += 1

      sleep count
      retry if count < 4
    end

    ACCEPT_JSON  = {'Accept'       => 'application/json, text/javascript, */*; q=0.01'}
    CONTENT_JSON = {'Content-Type' => 'application/json; charset=utf-8'}

    def get_json(url, filename = nil, options = {})
      get_page(url, filename, options.merge(request_headers: ACCEPT_JSON))
    end

    def post_page(url, options = {}, filename = nil)
      handling_exceptions do
        login_if_needed
        post(url, options, filename)
      end
    end

    def login_if_needed
      unless logged_in?
        logout
        login
      end
    end

    def get_body(url, filename = nil, options = {})
      body get(url, filename, options)
    end

    def get(url, filename = nil, options = {})
      puts "[#{url}]"
      uri     = uri(url)
      http    = http uri
      request = Net::HTTP::Get.new(uri.request_uri)

      # add_fake_headers request
      add_headers request, options[:request_headers]
      add_cookies request, uri
      add_body    request, options[:request_body]

      response = http.request(request)
      collect_cookies uri, response
      save_response(filename, request, response) if filename
      response
    end

    def post(url, options = {}, filename = nil)
      puts "[#{url}]"
      uri     = uri(url)
      http    = http uri
      params  = options[:params] || {}

      if params.values.any? {|value| value.is_a?(File)}
        name, file = params.find {|name, value| value.is_a?(File)}
        params.delete name
        new_params = {name => UploadIO.new(file, 'text/xml', File.basename(file))}.merge(params)
        request = Net::HTTP::Post::Multipart.new(uri.path, new_params)        
      else
        request = Net::HTTP::Post.new(uri.path)
        request.set_form_data params
      end

      add_headers request, options[:request_headers]
      add_cookies request, uri
      add_body    request, options[:request_body]

      response = http.request(request)
      collect_cookies uri, response
      save_response(filename, request, response) if filename
      response
    end

    def cookie_jar
      @jar ||= begin
        jar = HTTP::CookieJar.new
        jar.load(cookie_file) if File.exists? cookie_file
        jar
      end
    end

    def cookie_file
      Pkbot::Folder['cookies.txt'].to_s
    end

    def collect_cookies(uri, response)
      if response['set-cookie']
        puts "SET-COOKIE: #{response['set-cookie'].inspect}"

        cookie_jar.parse(response['set-cookie'], uri)
        cookie_jar.save cookie_file, session: true
      end
    end

    def body(response)
      if response['content-encoding'] == 'gzip'
        Zlib::GzipReader.new(StringIO.new(response.body), encoding: "ASCII-8BIT").read
      else
        response.body
      end
    end

    def parse_html(response)
      Nokogiri::HTML::Document.parse body(response)
    end

    def form_action(html)
      html.xpath("//form")[0]['action']
    end

    def extract_fields(html)
      Hash[html.xpath("//input").map {|node| [node['name'], node['value']]}]
    end
  end
end