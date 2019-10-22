require 'pp'
require File.expand_path("../snippet.rb", __FILE__)

module ConsoleHelper
  def _cs_init
    @__snippets = []
    @__snippets << _init_snippet(Snippet.recent.first) if Snippet.recent.first
  end

  def _init_snippet(snippet)
    snippet.console = self
    snippet
  end

  def _snip_reload(name)
    Snippet.reload name

    if idx = @__snippets.index {|snippet| snippet.name == name}
      @__snippets[idx] = _init_snippet(Snippet[name])
    end

    if @_snippet.name == name
      @_snippet = Snippet[name]
    end
  end

  def method_missing(name, *args, &block)
    if @_snippet && @_snippet.respond_to?(name)
      @_snippet.send(name, *args, &block)
    elsif @_snippet = @__snippets.find {|snippet| snippet.respond_to?(name)}
      @_snippet.send(name, *args, &block)
    elsif @_snippet = Snippet.recent.find {|snippet| snippet.respond_to?(name)}
      @__snippets.unshift _init_snippet(@_snippet)
      @_snippet.send(name, *args, &block)
    else
      super
    end
  end

  def snip(name = nil)
    name = name.try :to_sym

    if !name && @__snippets.first
      snippet = @__snippets.first
    elsif snippet = Snippet[name]
      @__snippets.unshift snippet
    else
      snippet = Snippet.make name
    end

    system "#{ENV['EDITOR']} #{snippet.file_name}"
  end

  def snips
    @__snippets
  end

  def snames
    puts Snippet.recent.map{|snippet| snippet.name.to_s}.join("\n")
  end
end
