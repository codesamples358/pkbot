class Module
  def delegate_keys(*args)
    to = args.shift
    methods = args.flatten
    methods.each do |name|
      module_eval <<-METHOD
        def #{name}
          #{to}[#{name.inspect}]
        end

        def #{name}=(value)
          #{to}[#{name.inspect}] = value
        end
      METHOD
    end
  end
end
