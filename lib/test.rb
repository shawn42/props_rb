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

  def keys
    ks = @_hash.keys
    if @parent
      ks | @parent.keys 
    else
      ks
    end
  end

  def each
    keys.each do |k|
      yield k, self[k]
    end
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

  def deps
    @dep_names || []
  end
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

module PropsRb
  module ClassMethods
    def prop(prop_name, &blk)
      parents = ancestors.select{|a|a.is_a? Class}
      propped_klass = parents.find do |parent_klass|
        MetaStore.get parent_klass
      end
      meta = MetaStore.get(propped_klass)

      if $VERBOSE
        warn "TODO raise error if meta not found"
        warn "TODO: clear all instances cache for [#{prop_name}]"
      end
      meta.properties[prop_name] = Prop.new(prop_name, &blk)
      meta.properties[prop_name]
    end

    def create(initial_props={})
      object = self.new
      object.initialize_props
      initial_props.each do |name, value|
        object.set(name, value)
      end
      object
    end

    def destroy
      DataStore.delete self.object_id
      CacheStore.delete self.object_id
      MetaStore.delete self.object_id
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
    parents = klass.ancestors.select{|a|a.is_a? Class}[1..-1]
    propped_klass = parents.find do |parent_klass|
      MetaStore.get(parent_klass)
    end
    parent_meta = MetaStore.get(propped_klass)
    meta = Meta.new parent_meta
    MetaStore.set(klass, meta)
  end

  def initialize_props
    meta = Meta.new(MetaStore.get(self.class))
    MetaStore.set(self.object_id, meta)
    props = meta.properties
    props.each do |name, prop|
      deps = prop.deps
      deps.each do |dep|
        meta.deps[dep] ||= []
        meta.deps[dep] << name
      end
    end
    props
  end

  def prop(prop_name, &blk)
    meta = MetaStore.get(self.object_id)
    CacheStore.delete self.object_id, prop_name
    meta.properties[prop_name] = Prop.new(prop_name, &blk)
    meta.properties[prop_name]
  end

  def set(k,v)
    DataStore.set(self.object_id, k, v)
    CacheStore.set(self.object_id, k, v)

    meta = MetaStore.get(self.object_id) || MetaStore.get(self.class)
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

    meta = MetaStore.get(self.object_id) || MetaStore.get(self.class)
    property_meta = meta.properties[k]
    binding.pry if !property_meta.respond_to?(:computed?)
    val = if property_meta.computed?
      property_meta.compute self
    else
      DataStore.get(self.object_id, k)
    end

    CacheStore.set(self.object_id, k, val)
    val
  end
end

if $0 == __FILE__
  class Person
    include PropsRb
    prop :first_name
    prop :last_name

    prop :full_name do |obj|
    "#{obj.get(:first_name)} #{obj.get(:last_name)}"
    end.depends_on(:first_name, :last_name)
  end

  class TitledPerson < Person
    include PropsRb
    prop :title
  end

  # when Person is extended, setup Meta
  titled_meta = MetaStore.get(TitledPerson)

  bill = TitledPerson.create first_name: "Billy"
  bill.set(:last_name, "Bob")
  bill.set(:title, "Mr")
  p bill.get(:title)
  p bill.get(:full_name)

  bill.prop :full_name do |obj|
    "#{obj.get(:title)} #{obj.get(:first_name)} #{obj.get(:last_name)}"
  end.depends_on :title, :first_name, :last_name


  bill.set(:title, "Dr")
  p bill.get(:full_name)

  # add prop cache, bust for monkey patching
  # serialization?
end



