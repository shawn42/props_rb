require_relative './props_rb'

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



