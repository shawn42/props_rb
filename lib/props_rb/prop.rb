module PropsRb
  class Prop
    attr_reader :name
    def initialize(name, &blk)
      @name = name
      @blk = blk
    end

    def computed?
      !@blk.nil?
    end

    def compute(target)
      @blk.call target
    end

    def depends_on(*dep_names)
      @dep_names = dep_names
      self
    end

    def deps
      @dep_names || []
    end
  end
end


