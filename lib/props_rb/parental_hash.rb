module PropsRb
  class ParentalHash
    def initialize(parent=nil)
      @parent = parent
      @_hash = HashWithIndifferentAccess.new
    end

    def [](k)
      v = @_hash[k]
      return v if v || @parent.nil?
      @parent[k]
    end

    def []=(k,v)
      @_hash[k] = v
    end

    def keys
      ks = @_hash.keys
      @parent ? ks | @parent.keys : ks
    end

    def each
      keys.each do |k|
        yield k, self[k]
      end
    end
  end
end

