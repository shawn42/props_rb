module PropsRb
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
#       :first_name => [:full_name],
#       :last_name => [:full_name]
#
#
#       prop :full_name do ... end.depends_on(:first_name, :last_name)
    end
  end
end
