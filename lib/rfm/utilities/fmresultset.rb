module Rfm

	# Methods to help translate xml_mini document into Rfm/Filemaker objects.
	module Fmresultset
	
	  module Resultset
	
	    def error
	    	self['fmresultset']['error']['code'].to_i
			end      
	       
	    def datasource
	      self['fmresultset']['datasource']
	    end
	    
	    def meta
	    	self['fmresultset']['metadata']
	    end
	    
	    def resultset
	    	self['fmresultset']['resultset']
	    end
	      
	    def date_format
	    	Rfm.convert_date_time_format(datasource['date-format'].to_s)
	  	end
	  	
	    def time_format
	    	Rfm.convert_date_time_format(datasource['time-format'].to_s)
	    end
	    
	    def timestamp_format
	    	Rfm.convert_date_time_format(datasource['timestamp-format'].to_s)
	    end
	
	    def foundset_count
	    	resultset['count'].to_s.to_i
	    end
	    	
	    def total_count
	    	datasource['total-count'].to_s.to_i
	    end
	    	
	    def table
	    	datasource['table']
			end
	    
	    def records
	      resultset['record'].rfm_force_array.rfm_extend_members(Record)
	    end
	
	    
	    def fields
	    	meta['field-definition'].rfm_force_array.rfm_extend_members(Field)
	    end
	    
	    def portals
		    meta['relatedset-definition'].rfm_force_array.rfm_extend_members(RelatedsetDefinition)
	    end
	
		end
		
		module Field
			def name
				self['name']
			end
			
			def result
	    	self['result']
	    end
	    
	    def type
	    	self['type']
	    end
	    
	    def repeats
	    	self['max-repeats']
	    end
	    
	    def global
	    	self['global']	
	    end
		end
		
		module RelatedsetDefinition
			def table
				self['table']
			end
			
			def fields
				self['field-definition'].rfm_force_array.rfm_extend_members(Field)
			end
		end
		
		module Record	
			def columns
				self['field'].rfm_force_array.rfm_extend_members(Column)
			end
			
			def record_id
				self['record-id']
			end
			
			def mod_id
				self['mod-id']
			end
			
			def portals
				self['relatedset'].rfm_force_array.rfm_extend_members(Relatedset)
			end
		end
			
		module Column
			def name
				self['name']
			end
			
			def data
				self['data'].values #['__content__']
			end
		end
		
		module Relatedset
			def table
				self['table']
			end
			
			def count
				self['count']
			end
			
			def records
				self['record'].rfm_force_array.rfm_extend_members(Record)
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