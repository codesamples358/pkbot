"C:\Program Files (x86)\GnuWin32\bin\wget.exe" --no-check-certificate "https://www.dropbox.com/s/nximoxmglhegbu9/pkbot.zip?dl=0" -O D:\pkbot.zip
"C:\Program Files (x86)\7-Zip\7z.exe" -aoa x D:\pkbot.zip -oD:\ -r
COPY D:\pkbot\get.bat D:\get_pkbot.bat /Y
gem install D:\pkbot\pkbot-0.0.1.gem