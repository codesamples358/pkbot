require 'net/ftp'

module Pkbot::Kommersant::Ftp
  extend self

  SERVER   = Pkbot::CONFIG['kommersant']['server']
  LOGIN    = Pkbot::CONFIG['kommersant']['login']
  PASSWORD = Pkbot::CONFIG['kommersant']['password']

  PDF_PATH = '/issues/DAILY.PDF/'
  XML_PATH = '/issues/XML/RU/Daily/'

  def list
    ftp.list
  end

  def pdf_files
    ftp.chdir(PDF_PATH)
    file_names ftp.list
  end

  def xml_files
    ftp.chdir(XML_PATH)
    file_names ftp.list
  end

  def file_names(list)
    list.map {|item| item.split(/ +/).last}
  end

  def issue_pdf(issue_number)
    if issue_number.ends_with?('p')
      num_s = issue_number[0 .. -2]
      pdf_files.find {|file| file =~ /kod\-#{pad_zeros num_s}[mM][\-\_]/}
    else
      pdf_files.find {|file| file =~ /kod\-#{pad_zeros issue_number}[\-\_]/}
    end
  end

  def pad_zeros(number)
    number.to_s.rjust 3, '0'
  end

  YEAR = Date.today.year - 2000

  def issue_xml(issue_number)
    if issue_number.ends_with?('p')
      num_s = issue_number[0 .. -2]
      xml_files.find {|file| file =~ /D#{YEAR}#{pad_zeros num_s}MO/}  
    else      
      xml_files.find {|file| file =~ /D#{YEAR}#{pad_zeros issue_number}/}
    end
  end

  def download(what, issue_number, where)
    file_name = send("issue_#{what}", issue_number)

    if file_name
      ftp.getbinaryfile(file_name, File.join(where, file_name))
      true
    end
  end

  def ftp
    @ftp = nil if @ftp.try(:closed?)

    @ftp ||= begin
      ftp = Net::FTP.new SERVER
      ftp.passive = true
      ftp.login LOGIN, PASSWORD
      ftp
    end
  end
end