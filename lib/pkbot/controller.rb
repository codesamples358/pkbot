module Pkbot
  module Controller
    extend self

    def process_issue(issue_number)
      issue = Pkbot::Issue.new issue_number
      issue.download
      issue.process_xml

      bo_issue = Pkbot::BackOffice::Issue.lookup(issue_number)
      bo_issue.import_articles issue.file(:pxml)
    end
  end
end