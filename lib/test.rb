require 'pry'
require 'active_support/core_ext/hash/indifferent_access'
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
end

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

  # def deps
  #   binding.pry
  #   @dep_names || []
  # end
end

class Meta
  attr_accessor :properties, :deps, :parent
  def initialize(parent=nil)
    if parent
      parent_props = parent.properties
      parent_deps = parent.deps
    end
    @parent = parent

    @properties = ParentalHash.new parent_props
    @deps = ParentalHash.new parent_deps
  end
end

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
end

class CacheStore
  def self.has_key?(id, k)
    @data ||= {}
    @data[id] ||= {}
    @data[id].has_key? k
  end

  def self.delete(id, k)
    @data ||= {}
    @data[id] ||= {}
    @data[id].delete k
  end

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
end

module PropsRb
  def set(k,v)
    DataStore.set(self.object_id, k, v)
    CacheStore.set(self.object_id, k, v)

    meta = MetaStore.get(self) || MetaStore.get(self.class)
    deps = meta.deps[k]
    if deps
      deps.each do |dep|
        CacheStore.delete(self.object_id, dep)
      end
    end

    v
  end

  def get(k)
    has_cached_value = CacheStore.has_key?(self.object_id, k)
    if has_cached_value
      return CacheStore.get(self.object_id, k)
    end

    meta = MetaStore.get(self) || MetaStore.get(self.class)
    property_meta = meta.properties[k]
    binding.pry if property_meta && !property_meta.respond_to?(:computed?)
    val = if property_meta.computed?
      property_meta.compute self
    else
      DataStore.get(self.object_id, k)
    end

    CacheStore.set(self.object_id, k, val)
    val
  end
end

class Person
  include PropsRb
#   prop :first_name
#   prop :last_name
#
#   prop :full_name do |obj|
#   "#{obj.get(:first_name)} #{obj.get(:last_name)}"
#   end.depends_on(:first_name, :last_name)
end

class TitledPerson < Person
end

person_meta = Meta.new
person_meta.properties[:first_name] = Prop.new(:first_name)
person_meta.properties[:last_name] = Prop.new(:last_name)
person_meta.properties[:full_name] = Prop.new :full_name do |obj|
  "#{obj.get(:first_name)} #{obj.get(:last_name)}"
end
MetaStore.set(Person, person_meta)

titled_meta = Meta.new(person_meta)
titled_meta.properties[:title] = Prop.new :title
MetaStore.set(TitledPerson, titled_meta)

bill = TitledPerson.new
bill.set(:first_name, "Billy")
bill.set(:last_name, "Bob")
bill.set(:title, "Mr")
p bill.get(:title)
p bill.get(:full_name)

bill_meta = Meta.new(titled_meta)
bill_meta.properties[:full_name] = Prop.new :full_name do |obj|
  "#{obj.get(:title)} #{obj.get(:first_name)} #{obj.get(:last_name)}"
end#.depends_on :title, :first_name, :last_name

bill_meta.deps[:first_name] = [:full_name]
bill_meta.deps[:last_name] = [:full_name]
bill_meta.deps[:title] = [:full_name]

MetaStore.set(bill, bill_meta)

bill.set(:title, "Dr")
p bill.get(:full_name)

# pull in prop management into magic helpers
# add prop cache, bust for monkey patching
# serialization?




