require 'forwardable'

class Object # @private :nodoc: all

	# Adds ability to forward methods to other objects using 'def_delegator'
	extend Forwardable

	# Adds methods to put instance variables in rfm_metaclass, plus getter/setters
	# This is useful to hide instance variables in objects that would otherwise show "too much" information.
  def self.meta_attr_accessor(*names)
		meta_attr_reader(*names)
		meta_attr_writer(*names)
  end
  
  def self.meta_attr_reader(*names)
    names.each do |n|
      define_method(n.to_s) {rfm_metaclass.instance_variable_get("@#{n}")}
    end
  end
  
  def self.meta_attr_writer(*names)
    names.each do |n|
      define_method(n.to_s + "=") {|val| rfm_metaclass.instance_variable_set("@#{n}", val)}
    end
  end
  
  # Give hash & arry a method to always return an array,
	# since XmlMini doesn't know which will be returnd for any particular element.
	# See Rfm Layout & Record where this is used.
	def rfm_force_array
		self.is_a?(Array) ? self : [self]
	end
  
private

	def rfm_metaclass
		class << self
			self
		end
	end
  
  def rfm_super
    SuperProxy.new(self)
  end
  
end # Object


class Array
	def extract_options!
	  last.is_a?(::Hash) ? pop : {}
	end
end

# Allows access to superclass object
class SuperProxy
  def initialize(obj)
    @obj = obj
  end

  def method_missing(meth, *args, &blk)
    @obj.class.superclass.instance_method(meth).bind(@obj).call(*args, &blk)
  end
end # SuperProxy




# May only be needed for ImportFmp module
class Time
	# Returns array of [date,time] in format suitable for FMP.
	def to_fm_components(reset_time_if_before_today=false)
		d = self.strftime('%m/%d/%Y')
		t = if (Date.parse(self.to_s) < Date.today) and reset_time_if_before_today==true
			"00:00:00"
		else
			self.strftime('%T')
		end
		[d,t]
	end
end # Time