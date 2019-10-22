require 'pkbot'

path = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift path
require "#{path}/pkbot.rb"

num = ARGV.size > 1 ? ARGV.pop : nil

issue = num && Pkbot::Issue.for(num)

# raise "1"  unless (issue && issue.bo_issue.id == "30315")

case ARGV[0]
when 'v'
  puts Pkbot::BUILD_TIME
when 'd'
  issue.download_process
when 'c'
  if ARGV[1] == 'gen_yml'
    issue.config.generate_from_xml
  else
    issue.config.generate_from_csv
  end
when 'faked'
  real_issue = Pkbot::Issue.for(num, issue_path: 'fake', clear_dir: true)
  real_issue.download_process
  real_issue.config.csv.create
when 'fakep'
  fake_issue = Pkbot::Issue.for(212, issue_path: 'fake')
  fake_issue.process  
when 'fake'
  real_issue = Pkbot::Issue.for(num, issue_path: 'fake', clear_dir: true)
  real_issue.download
  real_issue.config.csv.create
when 'p'
  issue.publish
when 'make'    
  issue.process
when 'make2'    
  issue.bo_issue.process2
when 'where'
  puts Pkbot::Location.path
when 'check_config'
  configs = issue.articles.map(&:config)
  puts "With photo: #{configs.select(&:photo).size}"
  puts "Not found:  #{issue.config.config.select {|c| c['article_id'].include? 'NOT'}.size}"
end
