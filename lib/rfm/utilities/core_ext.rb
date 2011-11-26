require 'forwardable'

class Object

	extend Forwardable

	# Adds methods to put instance variables in metaclass, plus getter/setters
  def self.meta_attr_accessor(*names)
		meta_attr_reader(*names)
		meta_attr_writer(*names)
  end
  
  def self.meta_attr_reader(*names)
    names.each do |n|
      define_method(n.to_s) {metaclass.instance_variable_get("@#{n}")}
    end
  end
  
  def self.meta_attr_writer(*names)
    names.each do |n|
      define_method(n.to_s + "=") {|val| metaclass.instance_variable_set("@#{n}", val)}
    end
  end
  
private

	def metaclass
		class << self
			self
		end
	end
  
end