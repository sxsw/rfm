module Rfm
	module Metadata
		class LayoutMeta < CaseInsensitiveHash
			
	    def field_controls
	      self['field_controls'] ||= CaseInsensitiveHash.new
	    end
	    
	  	def field_names
	  		field_controls.values.collect{|v| v.name}
	  	end
			
	  	def field_keys
	  		field_controls.keys
	  	end
	  	
	    def value_lists
				self['value_lists'] ||= CaseInsensitiveHash.new
	    end
		
		end
	end
end