module Rfm

  class CompoundQuery < Array # @private :nodoc:
  
  	attr_accessor :original_input, :query_type, :key_values, :key_arrays, :key_map, :key_map_string, :key_counter
  	
  	def self.build_test
  		new([{:field1=>['val1a','val1b','val1c'], :field2=>'val2'},{:omit=>true, :field3=>'val3', :field4=>'val4'}, {:omit=>true, :field5=>['val5a','val5b'], :field6=>['val6a','val6b']}], {})
  	end
  	
  	def initialize(query, options)
  		@options = options
  		@original_input = query
			@key_values = {}
			@key_arrays = []
			@key_map = []
			@key_map_string = ''
			@key_counter = 0

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
			build_query
  	end


  	def build_query(input=original_input)
  		case @query_type
	  	when 'mixed', 'compound'
	  		input.rfm_force_array.each do |hash|
	  			build_key_map(build_key_values(hash))
	  		end
	  		translate_key_map
	  		self.push '-findquery'
	  		self.push @key_values.merge('-query'=>@key_map_string)
	  	when 'standard'
	  		self.push '-find'
	  		self.push @original_input
	  	when 'recid'
	  		self.push '-find'
	  		self.push '-recid' => @original_input.to_s
	  	end
	  	self.push @options
	  	self
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
		def build_key_values(input_hash)
			input_hash = input_hash.clone
			keyarray = []
			omit = input_hash.delete(:omit)
			input_hash.each do |key,val|
				query_tag = []
				val = val.rfm_force_array
				val.each do |v|
					@key_values["-q#{key_counter}"] = key
					@key_values["-q#{key_counter}.value"] = v
					query_tag << "q#{key_counter}"
					@key_counter += 1
				end
				keyarray << query_tag
			end
			(keyarray << :omit) if omit
			@key_arrays << keyarray
			keyarray
		end

		
		# Input array of arrays.
		# Transform single key_array into key_map (array of requests)
		# Creates all combinations of sub-arrays where each combination contains one element of each subarray.
		def build_key_map(key_array)
			key_array = key_array.clone
			omit = key_array.delete(:omit)
			len = key_array.length
			flat = key_array.flatten
			rslt = flat.combination(len).select{|c| key_array.all?{|a| (a & c).size > 0}}.each{|c| c.unshift(:omit) if omit}
			@key_map.concat rslt
		end

		# Translate @key_map to FMP -query string
		def translate_key_map(keymap=key_map)
			keymap = keymap.clone
			inner = keymap.collect {|a| "#{'!' if a.delete(:omit)}(#{a.join(',')})"}
			outter = inner.join(';')
			@key_map_string << outter
		end

  end # CompoundQuery

end # Rfm
