module PropsRb
  class DataStore
    def self.set(id, k, v)
      @data ||= {}
      @data[id] ||= {}
      @data[id][k] = v
    end
    
    def self.get(id, k)
      @data ||= {}
      @data[id] ||= {}
      @data[id][k]
    end

    def self.delete(id, k=nil)
      @data ||= {}
      if k
        @data[id] ||= {}
        @data[id].delete k
      else
        @data.delete id
      end
    end
  end

  class CacheStore
    def self.has_key?(id, k)
      @data ||= {}
      @data[id] ||= {}
      @data[id].has_key? k.to_sym
    end

    def self.delete(id, k=nil)
      @data ||= {}
      if k
        @data[id] ||= {}
        @data[id].delete k.to_sym
      else
        @data.delete id
      end
    end

    def self.set(id, k, v)
      @data ||= {}
      @data[id] ||= {}
      @data[id][k.to_sym] = v
    end
    
    def self.get(id, k)
      @data ||= {}
      @data[id] ||= {}
      @data[id][k.to_sym]
    end
  end

  class MetaStore
    def self.set(k, v)
      @data ||= {}
      @data[k] = v
    end
    
    def self.get(k)
      @data ||= {}
      @data[k]
    end

    def self.delete(id, k=nil)
      @data ||= {}
      if k
        @data[id] ||= {}
        @data[id].delete k
      else
        @data.delete id
      end
    end
  end


end
