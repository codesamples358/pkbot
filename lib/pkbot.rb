require "pkbot/extensions"
require "active_support/all"
require 'forwardable'
require "nokogiri"
require 'yaml'

module Pkbot
  ROOT    = File.expand_path "../..", __FILE__
  TMP_DIR = File.join ROOT, "tmp"

  CONFIG = YAML.load_file File.expand_path("../pkbot/config.yml", __FILE__)
end

require 'pkbot/location'
require "pkbot/version"
require "pkbot/folder"

module Pkbot
  ISSUES_DIR = Folder['issues']
  mattr_accessor :mode
end

require "pkbot/back_office"
require "pkbot/kommersant"
require 'pkbot/issue'
require 'pkbot/article'
require "pkbot/controller"
require 'pkbot/config'
require 'pkbot/logging'

# require 'byebug'