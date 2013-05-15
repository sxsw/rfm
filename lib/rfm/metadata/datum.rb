require 'delegate'
module Rfm
  module Metadata
  
    class Datum   #< DelegateClass(Field)
    
      def get_mapped_name(name, resultset)
      	(resultset && resultset.layout && resultset.layout.field_mapping[name]) || name
      end
      
			def main_callback(cursor)
				resultset = cursor.top.object
				name = get_mapped_name(@attributes['name'].to_s, resultset)
				field = resultset.field_meta[name]
				data = @attributes['data']
				cursor.parent.object[name.downcase] = field.coerce(data)
			end
			
			def portal_callback(cursor)
				resultset = cursor.top.object
				table, name = @attributes['name'].to_s.split('::')
				#puts ['DATUM_portal_callback_01', table, name].join(', ')
				name = get_mapped_name(name, resultset)
				field = resultset.portal_meta[table.downcase][name.downcase]
				data = @attributes['data']
				#puts ['DATUM_portal_callback_02', resultset.class, table, name, field, data].join(', ')
				#(y resultset.portal_meta) unless field
				cursor.parent.object[name.downcase] = field.coerce(data)
			end
      
    end # Field
  end # Metadata
end # Rfm