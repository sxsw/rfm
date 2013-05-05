require 'delegate'
module Rfm
  module Metadata
  
    class Datum   #< DelegateClass(Field)
    
      def get_mapped_name(name, resultset)
      	(resultset && resultset.layout && resultset.layout.field_mapping[name]) || name
      end
      
			def end_element_callback(cursor)
				resultset = cursor.top.object
				name = get_mapped_name(@attributes['name'].to_s, resultset)
				field = resultset.field_meta[@attributes['name'].to_s.downcase]
				data = @attributes['data']
				cursor.parent.object[name.downcase] = field.coerce(data)
			end
      
    end # Field
  end # Metadata
end # Rfm