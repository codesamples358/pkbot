module Pkbot::BackOffice
  module Login
    def login
      id2 = "https://id2.action-media.ru"
      puts "Logging in..."

      link      = "#{id2}/logon/index?appid=74&reglink=&p=1&r=0.4971437090779589"
      auth_page = get link, "auth_page"

      html = parse_html auth_page

      login_fields  = extract_fields html
      login_fields['Login'] = LOGIN
      login_fields['Pass']  = PASSWORD
      login_fields['ConfirmationCode'] = ''

      auth_path = form_action html
      check_login_path = "#{id2}/Logon/CheckLogin"
      check_login_page = post(check_login_path, {
          params: {user: LOGIN, passwrod: PASSWORD, referrer: ''}
        }, 'check_login')

      url = "https://id2.action-media.ru#{auth_path}"
      puts "Logon POST path: #{url}"

      action_login = post(url, {
        params: login_fields,
        request_headers: {
          'Referer' => link
        }
      }, 'auth_post')

      post_logon   = get action_login['location'], 'post_logon'
      logon_token  = action_login['location'][/Token=([\w\-]+)/, 1]
      bo_login_url ="http://bo.profkiosk.ru/api/auth/login?returnUrl=%2fdept%2f8%2fpress%2f187%2fyear%2f2017%2fissue%2f&token=#{logon_token}"
      get bo_login_url, 'bo_login'
    end

    def logout
      cookie_jar.clear
    end

    AUTH_COOKIE = '.ASPXAUTH'
    def logged_in?
      cookie = cookie_jar.find {|cookie| cookie.name == AUTH_COOKIE}
      cookie && cookie.expires > Time.now
    end

    def relogin
      logout
      login
    end
  end
end