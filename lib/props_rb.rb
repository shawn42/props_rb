require "props_rb/version"

require 'awesome_print'
require 'active_support/core_ext/hash/indifferent_access'
require 'pry'

module PropsRb
  class Store
    # not liking that the store is class-aware
    def self.initialize_meta(key)
      @meta ||= {}
      @meta[key] = Meta.new
    end

    def self.meta_for(key)
      @meta ||= {}
      @meta[key]
    end

    def self.destroy(key)
      @meta ||= {}
      @meta.delete key
    end
  end

  def initialize_props
    Store.initialize_meta(self)
    meta = Store.meta_for self
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

  def destroy
    Store.destroy(self)
  end

  def get(name)
    meta = Store.meta_for(self)
    return if meta.nil?
    prop = meta.properties[name]
    return if prop.nil?

    if prop.computed?
      if meta.cache.has_key? name
        meta.cache[name]
      else
        meta.cache[name] = prop.compute self
      end
    else
      meta.values[name]
    end
  end

  def set(name, value)
    meta = Store.meta_for(self)
    return if meta.nil?
    prop = meta.properties[name]
    return if prop.nil?

    if prop.computed?
      raise "cannot set computed property"
    else
      if meta.values[name] != value
        meta.deps[name].each do |prop_name|
          meta.cache.delete prop_name
        end
        meta.values[name] = value
      end
    end
  end

  module SharedMethods
    def prop(prop_name, &blk)
      meta = Store.meta_for(self) || Store.initialize_meta(self)
      meta.properties[prop_name] = Prop.new(prop_name, &blk)
      meta.properties[prop_name]
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
    klass.include SharedMethods
    Store.initialize_meta(klass)
  end

  module ClassMethods
    include SharedMethods
    def create(initial_props={})
      object = self.new
      object.initialize_props
      initial_props.each do |name, value|
        object.set(name, value)
      end
      object
    end

  end

  class Meta
    attr_accessor :properties, :values, :cache, :deps
    def initialize
      @properties = HashWithIndifferentAccess.new
      @values = HashWithIndifferentAccess.new
      @cache = HashWithIndifferentAccess.new
      @deps = HashWithIndifferentAccess.new
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
    end

    def deps
      @dep_names || []
    end
  end
end

