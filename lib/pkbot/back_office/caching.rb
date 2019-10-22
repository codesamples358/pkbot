module Pkbot::BackOffice::Caching
  def tmp_file(dir, name)
    tmp_dir = Pkbot::Folder['cached_requests', dir]
    tmp_dir.file name
  end

  def write(dir, filename, &block)
    File.open(tmp_file(dir, filename), 'w', &block)
  end

  def save_response(dir, request, response)
    write(dir, 'request_headers') {|file| file.write(request.to_hash.inspect)}
    write(dir, 'request_path')    {|file| file.write(request.path)}
    write(dir, 'request_body')    {|file| file.write(request.body)}
    write(dir, 'response_status') {|file| file.write(response.code)}
    write(dir, 'response_headers'){|file| file.write(response.to_hash.inspect)}
    write(dir, 'response_body')   {|file| file.write(body response)}
  end

  def get_cached(dir)
    file = tmp_file(dir, 'response_body')

    if File.exists?(file)
      enc     = File.read(tmp_file(dir, 'response_headers'))[/charset=([\w\-]+)/, 1]
      enc_str = enc ? ":#{enc}" : nil
      File.open(file, "r#{enc_str}").read
    end
  end
end