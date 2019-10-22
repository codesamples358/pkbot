require 'net/http'
require 'cgi'
require 'nokogiri'

module Pkbot::BackOffice
  require_relative 'back_office/http'
  require_relative 'back_office/login'
  require_relative 'back_office/caching'

  extend Http
  extend Login
  extend Caching
  extend self

  # ISSUES_URL = "http://bo.profkiosk.ru/dept/8/press/187/year/#{Date.today.year}/issue/"
  ISSUES_URL = "http://bo.profkiosk.ru/!/content/press/187?tab=periods/index"
  # http://bo.profkiosk.ru/!/content/press/187?tab=periods/index
  HOST       = "bo.profkiosk.ru"

  LOGIN_URL = 'https://id2.action-media.ru/Account/ShortLogin'
  LOGIN     = Pkbot::CONFIG['back_office']['login']
  PASSWORD  = Pkbot::CONFIG['back_office']['password']
  
end

require_relative 'back_office/entity'
require_relative 'back_office/issue'
require_relative 'back_office/article'
require_relative 'back_office/html_page'