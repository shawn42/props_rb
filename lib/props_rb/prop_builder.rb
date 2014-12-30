module PropsRb
  class PropBuilder
    def initialize(prop, meta)
      @prop = prop
      @meta = meta
    end

    def depends_on(*deps)
      deps.each do |dep|
        @meta.deps[dep] ||= []
        @meta.deps[dep] << @prop.name
      end
    end
  end
end

