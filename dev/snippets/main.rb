Snippet.add(:main) do
  setters(
    dev_default_mode: 'dev',
    mode: 'dev',

    debug_mode: {
      no_cache: true,
      default_year: 2045,
      no_ex: :off
    },

    dev_mode: {
      default_year: 2045
    },

    real_issue: 112
  )

  def set_mode
    mode(dev_default_mode) if Pkbot::Location.development?

    puts "Setting #{mode} mode..."
    return unless mode_config
    process_mode_config
  end

  def try_process
    issue.download
    issue.config.generate_from_xml
    issue.process
  end

  def process_mode_config
    if mode_config[:no_cache]
      [:Issues].each do |subclass|
        klass = Pkbot::BackOffice::HtmlPage.const_get(subclass)
        klass.cache = false
      end

      puts "All caching disabled."
    end

    if mode_config[:default_year]
      puts "Forcing BackOffice to work inside of #{mode_config[:default_year]} year."
      $BO_YEAR = mode_config[:default_year]
    end

    if mode_config[:no_ex] == :off
      puts "no_ex disabled: all exceptions are thrown"
      $DISABLE_NO_EX = true
    end
  end

  def mode_config
    cfg = send("#{mode}_mode") rescue {}
    instance_variable_set("@#{mode}_mode_config", instance_variable_get("@#{mode}_mode_config") || cfg)
  end

  def reload_config(key, value)
    mode_config[key] = value
    process_mode_config
  end

  def nc!
    reload_config :no_cache, true
  end

  def yn! # year now
    reload_config :default_year, 2018
  end

  def yt! # year test
    reload_config :default_year, 2045
  end

  def ex!
    reload_config :no_ex, :off
  end

  def try_config(key)
    mode_config.try(:[], key)
  end

  set_mode

  # TEST_ISSUE = 226

  def fake_issue
    @fake_issue ||= Pkbot::Issue.for(TEST_ISSUE, issue_path: 'fake')
  end

  def test_issue
    @fake_issue ||= Pkbot::Issue.for(TEST_ISSUE)
  end

  def issue(num = real_issue)
    # @issues ||= {}
    # @issues[num] ||= Pkbot::Issue.for(num)

    Pkbot::Issue.for(num)
  end

  def bo_article
    @bo_article ||= bo_issue.articles.first
  end

  alias_method :ba, :bo_article

  def xml_article
    bo_article.xml_article
  end

  alias_method :xa, :xml_article

  def bo_issue
    issue.bo_issue
  end

  alias_method :bi, :bo_issue

  def issues
    opts = {year: try_config(:default_year)} if try_config(:default_year)
    Pkbot::BackOffice::HtmlPage::Issues.new(opts).issues
  end

  def issue_html
    issue.html
  end

  alias_method :ih, :issue_html

  def article_html
    issue_html.articles.first
  end

  alias_method :ah, :article_html

  def d(num = real_issue)
    issue(num).download
    issue(num).process_xml
  end

  def make(num = real_issue)
    issue(num).process
  end

  def make2(num = real_issue)
    issue(num).bo_issue.process2
  end

  def test_process
    fake_issue.process
  end

  def fake!(number = nil)
    number ||= issue.number
    issue = Pkbot::Issue.for number

    fake_dir = Pkbot::Folder['issues/fake']

    [fake_dir, test_issue.issue_dir].each do |dir|
      `rm -rf #{dir}`
      `cp -R #{issue.issue_dir} #{dir}`
    end
  end

  def ftp
    Pkbot::Kommersant::Ftp
  end
end
