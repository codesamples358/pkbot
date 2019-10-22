class Snippet
  ROOT = File.expand_path('../snippets', __FILE__)
  ERB  = ERB.new File.read File.expand_path('../snippet.erb', __FILE__)
  ALL  = []
  class_attribute :created

  def self.make(name)
    new(name).tap do |snippet|
      snippet.write
    end
  end

  def self.add(name, &block)
    new(name).tap do |snippet|
      snippet.instance_eval(&block)
      ALL.push snippet
    end
  end

  def self.new_sublcass(name)
    const_set(name.to_s.camelize, Class.new(self, &block))
  end

  attr_reader :name, :file_name
  attr_accessor :console

  def initialize(name)
    @name = name
  end

  def file_name
    File.join ROOT, "#{name}.rb"
  end

  def time
    File.ctime file_name
  end

  def write
    unless File.exists?(file_name)
      File.open(file_name, "w") {|file| file.write(ERB.result binding)}
    end
  end

  def self.load_all
    Dir["#{ROOT}/*.rb"].each do |file|
      require file
    end

    ALL
  end

  def self.recent
    ALL.sort_by(&:time).reverse
  end

  def self.reload(name)
    ALL.reject! {|snippet| snippet.name == name}
    load "#{ROOT}/#{name}.rb"
  end

  def self.[](name)
    recent.find {|snippet| snippet.name == name}
  end


  def alias_method(a, m)
    singleton_class.class_eval do
      alias_method a, m
    end
  end

  def delegate_to(what)
    mod = Module.new do
      class_eval %Q{
        def respond_to?(meth)
          super || #{what}.try(:respond_to?, meth)
        end

        def method_missing(meth, *args, &blk)
          #{what}.send(meth, *args, &blk)
        rescue NoMethodError
          super
        end
      }
    end

    self.extend mod
  end

  def _test(name)
    @test ||= Testing::Tests.const_get(name.camelize).new(Testing::Suit.new(output: STDOUT))
  end

  def setting(key)
    DbSetting.where(key: "#{@name}.#{key}").first_or_initialize
  end

  def set(key, value)
    setting = setting key
    setting.value = value.to_json
    setting.save
  end

  def get(key)
    value = setting(key).try(:value)
    value && json(value)
  end

  def json(value)
    JSON(value)
  rescue JSON::ParserError
    JSON("[#{value}]")[0]
  end


  def accessor(*names)
    names.each do |name|
      self.instance_eval %Q{
        def #{name}
          @#{name}
        end
      }
    end
  end

  def delegate(*args)
    singleton_class.class_eval do
      delegate *args
    end
  end

  def setters(args)
    if args.is_a?(Hash)
      args.each do |name, default_value|
        def_setter name, default_value
      end
    end
  end

  def def_setter(name, default_value)
    instance_eval %Q{
      def #{name}(v = nil)
        if !v
          @#{name} || #{default_value.inspect}
        else
          @#{name} = v
        end
      end
    }
  end

  load_all
  self['main'] # auto-load main
end
