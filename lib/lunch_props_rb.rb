class ShadowHash
  def initialize(parent=nil)
    @parent = parent
    @values = {}
  end

  def keys
    if @parent
      @parent.keys | @values.keys
    else
      @values.keys
    end
  end

  def each
    keys.each do |k|
      yield k, self[k]
    end
  end

  def [](key)
    @values[key] || @parent[key]
  end

  def []=(key,val)
    @values[key] = val
  end

  # only deletes from our layer
  def delete(key)
    @values.delete key
  end
end

require "props_rb/version"

require 'awesome_print'
require 'active_support/core_ext/hash/indifferent_access'
module PropsRb
  class Store
    def self.give_props_to(object)
      ShadowHash.new
    end

    def self.set_props_for(key, props)
      @props ||= {}
      @props[key] = props
    end

    def self.props_for(key)
      @props ||= {}
      @props[key]
    end

    def self.data_for(key)
      @meta ||= {}
      # use equal and hash methods to define how things will be cached
      # puts "data_for: #{key.inspect}"
      @meta[key] ||= Meta.new
      # @meta[key] ||= Meta.new
    end

    def self.destroy(key)
      # puts "destroying: #{key.inspect}"
      @meta ||= {}
      @meta.delete key
    end
  end

  def initialize_props
    # TODO loop up the ancestors
    parent_props = Store.props_for(self.class)

    props = Store.props_for(self)

    parent_props.each do |name, prop|
      deps = prop.deps
      deps.each do |dep|
        meta.deps[dep] ||= []
        meta.deps[dep] << name
      end
    end

    Store.data_for(self)
  end

  def destroy
    Store.destroy(self)
  end

  def get(name)
    meta = Store.data_for(self)
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
    meta = Store.data_for(self)
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
      meta = Store.data_for(self)
      meta.properties[prop_name] = Prop.new(prop_name, &blk)
      meta.properties[prop_name]
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
    klass.include SharedMethods
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
    attr_accessor :values, :cache, :deps
    def initialize
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

if $0 == __FILE__
  class Person
    include PropsRb
    prop :first_name
    prop :last_name

    prop :full_name do |obj|
      "#{obj.get(:first_name)} #{obj.get(:last_name)}"
    end.depends_on(:first_name, :last_name)

    def initialize
      initialize_props
    end
  end

  person = Person.create first_name: "Billy", last_name: "Bob"
  person2 = Person.create first_name: "Stevie", last_name: "Ray"
  # p person.get(:full_name)
  # person.set(:first_name, "Darth")
  # person.set(:last_name, "Vader")
  # p person.get(:full_name)
  # p person.get('full_name')

  # person.prop :wah do |obj|
  #   "#{obj.get(:first_name)} monkey"
  # end.depends_on(:first_name)

  p person.get(:full_name)
  p person2.get(:full_name)

  # ap PropsRb::Store.instance_variable_get('@meta')
  ap PropsRb::Store.instance_variable_get('@meta').keys
  person.destroy
  ap PropsRb::Store.instance_variable_get('@meta').keys
  # TODO 
  # make something.another.foo work? (may need to switch to Signals for that)

end

require 'pry'
binding.pry

