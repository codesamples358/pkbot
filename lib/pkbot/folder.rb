class Pkbot::Folder
  attr_accessor :options

  HOME_DIR         = File.expand_path '~'
  PKBOT_DIR        = File.join HOME_DIR, 'pkbot'
  DEFAULT_ENCODING = 'UTF-8'

  TRY_ENCODINGS    = ['BOM|UTF-8', 'UTF-8']

  def self.[](*rel_path)
    new File.join(*rel_path)
  end

  def self.tmp
    new '', root: Pkbot::TMP_DIR
  end

  def initialize(path, options = {})
    @options = options
    @path    = path

    if dir? && !options[:force_file]
      FileUtils.mkdir_p(full_path)
    else
      FileUtils.mkdir_p(File.dirname full_path)
    end
  end

  def binary
    @binary = true
    self
  end

  def full_path
    File.join root, @path
  end

  def root
    options[:root] || PKBOT_DIR
  end

  def basename
    File.basename @path
  end

  def dir?
    !basename.include?('.')
  end

  def [](*path)
    self.class.new File.join(@path, *path), root: options[:root]
  end

  def file(*path)
    self.class.new File.join(@path, *path), force_file: true
  end

  def exists?
    File.exists? full_path
  end

  def expand(rel_path)
    if rel_path.starts_with?('/')
      rel_path
    else
      self[rel_path].to_s
    end
  end

  def to_s
    full_path
  end

  def to_str
    to_s
  end

  BOM_BYTES = "\xEF\xBB\xBF"

  def bom?
    first_3_bytes.bytes == BOM_BYTES.bytes
  end

  def first_3_bytes
    File.binread(full_path, 3)
  end

  def utf8
    bom? ? "BOM|UTF-8" : "UTF-8"
  end

  def try_enc
    [utf8, 'CP1251']
  end

  def write(text)
    unless dir?
      enc = @binary ? "wb" : "w:UTF-8" 
      File.open(full_path, enc) {|file| file.write text}
    end
  end

  def read_enc(enc)
    File.open(full_path, "r:#{enc}:UTF-8") {|io| io.read}
  end

  def read
    try_enc.each do |enc|
      text = read_enc(enc)
      return text if text.valid_encoding?
    end
  end

  def clear!
    FileUtils.rm_rf(File.join full_path, '*')
  end

  def create
    File.open(full_path, 'w') {|file| file.write('')} unless exists?
  end
end