### Adds method to put instance variables in metaclass, plus getter/setters ###

class Object
  def meta_attr_accessor(*names)
    names.each do |n|
      define_method(n.to_s) {(class << self; self; end).instance_variable_get("@#{n}")}
      define_method(n.to_s + "=") {|val| (class << self; self; end).instance_variable_set("@#{n}", val)}
    end
  end
end