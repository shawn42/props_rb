require "props_rb/version"

require 'awesome_print'
require 'active_support/core_ext/hash/indifferent_access'
module PropsRb
  class Store
    def self.meta_for(key, prototype=nil)
      @meta ||= {}
      # use equal and hash methods to define how things will be cached
      # puts "meta_for: #{key.inspect}"
      @meta[key] ||= prototype
      @meta[key] ||= Meta.new
    end

    def self.destroy(key)
      # puts "destroying: #{key.inspect}"
      @meta ||= {}
      @meta.delete key
    end
  end

  def initialize_props
    parent_meta = Store.meta_for(self.class)
    meta = Store.meta_for(self, parent_meta)

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
      meta = Store.meta_for(self)
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

module HashByGuid
  # TODO move to PropsRb#props_equal?
  def equal?(other)
    # puts "EQ: #{self.inspect} : #{other.inspect}"
    meta = PropsRb::Store.meta_for self
    other_meta = PropsRb::Store.meta_for other

    return meta.values == other_meta.values
  end

  def hash
    get('guid') || super
  end
end

if $0 == __FILE__
  class Person
    include HashByGuid
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

  person = Person.create first_name: "Billy", last_name: "Bob", guid: 8
  p person.get(:full_name)
  person.set(:first_name, "Darth")
  person.set(:last_name, "Vader")
  p person.get(:full_name)
  p person.get('full_name')

  person.prop :wah do |obj|
    "#{obj.get(:first_name)} monkey"
  end.depends_on(:first_name)

  p person.get(:wah)

  ap PropsRb::Store.instance_variable_get('@meta').keys
  person.destroy
  ap PropsRb::Store.instance_variable_get('@meta').keys
  # TODO 
  # make something.another.foo work? (may need to switch to Signals for that)

end







