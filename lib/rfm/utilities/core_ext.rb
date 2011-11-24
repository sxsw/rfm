# Give hash & arry a method to always return an array,
# since XmlMini doesn't know which will be returnd for any particular element.
# See Rfm Layout & Record where this is used.
class Object
	def rfm_force_array
		self.is_a?(Array) ? self : [self]
	end
end
