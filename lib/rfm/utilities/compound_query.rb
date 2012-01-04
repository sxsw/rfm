module Rfm

  class CompoundQuery < Array # @private :nodoc:
  
  	attr_accessor :original_input, :query_type, :key_values, :key_map, :key_counter
  	
  	
  	
  	def self.build_test
  		#new({:field1=>['val1a','val1b','val1c'], :field2=>'val2'}, {})
  		new({:field1=>'val1', :field2=>'val2', :omit=>{:field3=>'val3', :field4=>'val4'}}, {})
  	end
  	
  	def build_query(input=original_input)
  		case @query_type
  		when 'mixed'
  			omits = input.delete(:omit)
	  		build_key_values input
	  		build_key_values omits, true
	  	when 'compound'
	  		input.each do |hash|
	  			build_key_values(hash, hash[:omit])
	  		end
	  	when 'standard'
	  	when 'recid'
	  	end
  	end

  	
  	def initialize(query, options)
  		@original_input = query
  		case query
			when Hash
				if query.detect{|k,v| v.kind_of? Array or k == :omit}
					@query_type = 'mixed'
				else
					@query_type = 'standard'
				end
			when Array
				@query_type = 'compound'
			else
				@query_type = 'recid'
			end
			@key_values = {}
			@key_map = []
			@key_counter = 0
  	end


		# Methods for Rfm::Layout to build complex queries
		# Perform RFM find using complex boolean logic (multiple value options for a single field)
		# Mimics creation of multiple find requests for "or" logic
		#	
		# Master controlling method to build fmresultset uri for -findquery command
		# Use: {:field1=>['val','val2','val3'], :field2=>'val4', :omit{:field3=>[...], :field4=>''}}
		def assemble_query(query_hash)
			key_values, key_map, omit_map = build_key_values(query_hash)
			key_values.merge!("-query"=>query_translate(combine_query(key_map)))
			(key_values["-query"] <<  ";" + query_translate(combine_query(omit_map), true)) if omit_map.size > 0
			key_values
		end  

		# Build key-value definitions and query map  '-q1...'
		# Converts query_hash to fmresultset uri format for -findquery query type.
		def build_key_values(input_hash, omit=false)

			input_hash.each do |key,val|
				#val = val.rfm_force_array
				
				query_tag = []
				val.each do |v|
					@key_values["-q#{key_counter}"] = key
					@key_values["-q#{key_counter}.value"] = v
					query_tag << "q#{key_counter}"
					@key_counter += 1
				end
				
				@key_map << query_tag
			end
			# 			query_hash.each {|key,val| build_values.call(key,val,false)}
			# 			omit_hash.each {|key,val| build_values.call(key,val,true)} if omit_hash
			# 			return key_values, key_map, omit_map
		end

		
		# Input array of arrays.
		# Creates all combinations of sub-arrays where each combination contains one element of each subarray.
		def mix_key_map(key_array=key_map)
			len = key_array.length
			flat = key_array.flatten
			rslt = flat.combination(len).select{|c| key_array.all?{|a| (a & c).size > 0}}
		end

		# Translate @key_map to FMP -query string
		def translate_key_map(omit=false, key_array=key_map)
			rslt = ""
			sub = key_array.collect {|a| "#{'!' if omit}(#{a.join(',')})"}
			sub.join(";")
		end

  end # CompoundQuery

end # Rfm
