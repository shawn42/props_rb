require 'awesome_print'
require 'active_support/core_ext/hash/indifferent_access'
require 'pry'

require_relative "./props_rb/version"
require_relative "./props_rb/parental_hash"
require_relative "./props_rb/prop_builder"
require_relative "./props_rb/stores"
require_relative "./props_rb/meta"
require_relative "./props_rb/prop"


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
    prop = Prop.new(prop_name, &blk)
    meta.properties[prop_name] = prop
    PropBuilder.new(prop, meta)
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
