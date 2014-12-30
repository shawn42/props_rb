require_relative '../lib/test'
# require_relative '../lib/props_rb'

describe "Props.rb" do
  let(:person_klass) { Class.new do
      include PropsRb
      prop :first_name
      prop :last_name

      prop :full_name do |obj|
      "#{obj.get(:first_name)} #{obj.get(:last_name)}"
      end.depends_on(:first_name, :last_name)
    end }
 
  describe "basic class level prop" do
    it 'works' do
      person = person_klass.create first_name: "Billy", last_name: "Bob"
      expect(person.get(:full_name)).to eq("Billy Bob")
  
      person.set(:first_name, "Darth")
      person.set(:last_name, "Vader")
      expect(person.get(:full_name)).to eq("Darth Vader")
    end
  end

  describe "inherited props" do
    let(:person_klass) { Class.new do
        include PropsRb
        prop :first_name
        prop :last_name
  
        prop :full_name do |obj|
        "#{obj.get(:first_name)} #{obj.get(:last_name)}"
        end.depends_on(:first_name, :last_name)
      end }

    let(:sub_klass) { Class.new(person_klass) do
      include PropsRb
    end}

    let(:override_klass) { Class.new(person_klass) do
        include PropsRb
        prop :middle_name
        prop :full_name do |obj|
        "#{obj.get(:first_name)} #{obj.get(:middle_name)} #{obj.get(:last_name)}"
        end.depends_on(:first_name, :last_name, :middle_name)
      end }

    it 'gets props from ancestery' do
      person = sub_klass.create first_name: "Billy", last_name: "Bob"
      expect(person.get(:full_name)).to eq("Billy Bob")
  
      person.set(:first_name, "Darth")
      person.set(:last_name, "Vader")
      expect(person.get(:full_name)).to eq("Darth Vader")
    end

    it 'can override props from parents' do
      person = override_klass.create first_name: "Billy", last_name: "Bob", middle_name: "Matthew"
      expect(person.get(:full_name)).to eq("Billy Matthew Bob")
      person.set(:middle_name, "B")
      expect(person.get(:full_name)).to eq("Billy B Bob")
    end
  end

  describe 'per instance props' do
    it 'can add prop to instance' do
      billy = person_klass.create first_name: "Billy", last_name: "Bob"
      billy.prop :wah do |obj|
        "#{obj.get(:first_name)} monkey"
      end.depends_on(:first_name)
      expect(billy.get(:wah)).to eq("Billy monkey")
      billy.set(:first_name, "William")
      CacheStore.delete billy.object_id, :wah
      expect(billy.get(:wah)).to eq("William monkey")
    end

    it 'can override class or parent props' do
      billy = person_klass.create first_name: "Billy", last_name: "Bob"
      billy.prop :full_name do |obj|
        "#{obj.get(:first_name)} unknown"
      end.depends_on(:first_name)

      expect(billy.get(:full_name)).to eq("Billy unknown")
      billy.set(:first_name, "William")
      expect(billy.get(:full_name)).to eq("William unknown")
    end
  end

  
end
