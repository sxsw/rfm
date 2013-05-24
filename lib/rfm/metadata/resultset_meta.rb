module Rfm
	module Metadata
		class ResultsetMeta < CaseInsensitiveHash
			
			def field_meta
				self['field_meta'] ||= CaseInsensitiveHash.new
			end
			
			def portal_meta
				self['portal_meta'] ||= CaseInsensitiveHash.new
			end
			
	  	def new_field_handler(attributes)
	  		f = Field.new(attributes)
				# 	name = attributes['name']
				# 	self[name] = f
	  		f
	  	end
		
		end
	end
end