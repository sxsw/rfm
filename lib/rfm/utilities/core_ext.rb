require 'forwardable'

class Object # :nodoc: all

	# Adds ability to forward methods to other objects
	extend Forwardable

	# Adds methods to put instance variables in metaclass, plus getter/setters
	# This is useful to hide instance variables in objects that would otherwise show "too much" information.
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
  
  # Give hash & arry a method to always return an array,
	# since XmlMini doesn't know which will be returnd for any particular element.
	# See Rfm Layout & Record where this is used.
	def rfm_force_array
		self.is_a?(Array) ? self : [self]
	end
  
private

	def metaclass
		class << self
			self
		end
	end
  
end
