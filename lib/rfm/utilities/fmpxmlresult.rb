module Rfm

	# Methods to help translate xml_mini document into Rfm/Filemaker objects.
	module Fmpxmlresult
		def self.extended(obj)
		  obj.instance_variable_set :@root, obj
		  obj.extend Resultset
		end
	
	  module Resultset
	
	    def error
	    	self['FMPXMLRESULT']['ERRORCODE']['__content__'].to_i
			end      
	       
	    def datasource
	      self['FMPXMLRESULT']['DATABASE']
	    end
	    
	    def meta
	    	self['FMPXMLRESULT']['METADATA']
	    end
	    
	    def resultset
	    	self['FMPXMLRESULT']['RESULTSET']
	    end
	      
	    def date_format
	    	Rfm.convert_date_time_format(datasource['DATEFORMAT'].to_s)
	  	end
	  	
	    def time_format
	    	Rfm.convert_date_time_format(datasource['TIMEFORMAT'].to_s)
	    end
	    
	    def timestamp_format
	    	#Rfm.convert_date_time_format(datasource['timestamp-format'].to_s)
	    	"#{date_format} #{time_format}"
	    end
	
	    def foundset_count
	    	resultset['FOUND'].to_s.to_i
	    end
	    	
	    def total_count
	    	datasource['RECORDS'].to_s.to_i
	    end
	    	
	    def table
	    	#datasource['table'].to_s
	    	'not-defined'
			end
	    
	    def records
	      resultset['ROW'].rfm_force_array.rfm_extend_members(Record, self)
	    end
	
	    
	    def fields
	    	meta['FIELD'].rfm_force_array.rfm_extend_members(Field, self)
	    end
	    
	    def portals
		    #meta['relatedset-definition'].rfm_force_array.rfm_extend_members(RelatedsetDefinition)
		    [].rfm_extend_members(RelatedsetDefinition)
	    end
	
		end
		
		module Field
			def name
				self['NAME']
			end
			
			def result
	    	self['TYPE']
	    end
	    
	    def type
	    	#self['type']
	    	'not-defined'
	    end
	    
	    def max_repeats
	    	self['MAXREPEAT']
	    end
	    
	    def global
	    	#self['global']
	    	'not-defined'
	    end
		end
		
		module RelatedsetDefinition
			def table
				#self['table']
				'not-defined'
			end
			
			def fields
				#self['field-definition'].rfm_force_array.rfm_extend_members(Field)
				[].rfm_extend_members(Field)
			end
		end
		
		# May need to add @parent to each level of heirarchy in #rfm_extend_member,
		# so we can get the container and it's parent from records, columns, data, etc..
		module Record	
			def columns
				self['COL'].rfm_force_array.rfm_extend_members(Column, self)
			end
			
			def record_id
				self['RECORDID']
			end
			
			def mod_id
				self['MODID']
			end
			
			def portals
				#self['relatedset'].rfm_force_array.rfm_extend_members(Relatedset)
				[].rfm_extend_members(Relatedset)
			end
		end
			
		module Column
			def name
				n = parent.index self
				root.fields[n].name				
			end
			
			def data
				self['DATA'].rfm_force_array.collect{|d| d['__content__']}
			end
		end
		
		module Relatedset
			def table
				#self['table']
				'not-defined'
			end
			
			def count
				#self['count']
				0
			end
			
			def records
				#self['record'].rfm_force_array.rfm_extend_members(Record)
				[].rfm_extend_members(Record)
			end
		end
	
	end
    
	def convert_date_time_format(fm_format)
	  fm_format.gsub!('MM', '%m')
	  fm_format.gsub!('dd', '%d')
	  fm_format.gsub!('yyyy', '%Y')
	  fm_format.gsub!('HH', '%H')
	  fm_format.gsub!('mm', '%M')
	  fm_format.gsub!('ss', '%S')
	  fm_format
	end
    
end