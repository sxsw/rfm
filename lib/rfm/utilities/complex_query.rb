module Rfm

  module ComplexQuery # @private :nodoc:
		# Methods for Rfm::Layout to build complex queries
		# Perform RFM find using complex boolean logic (multiple value options for a single field)
		# Mimics creation of multiple find requests for "or" logic
		# Use: rlayout_object.query({'fieldOne'=>['val1','val2','val3'], 'fieldTwo'=>'someValue', ...})
		def query(hash_or_recid, options = {})
		  if hash_or_recid.kind_of? Hash
		    get_records('-findquery', assemble_query(hash_or_recid), options)
		  else
		    get_records('-find', {'-recid' => hash_or_recid.to_s}, options)
		  end
		end

		# Build ruby params to send to -query action via RFM
		def assemble_query(query_hash)
			key_values, query_map = build_key_values(query_hash)
			key_values.merge("-query"=>query_translate(array_mix(query_map)))
		end

		# Build key-value definitions and query map  '-q1...'
		def build_key_values(qh)
			key_values = {}
			query_map = []
			counter = 0
			qh.each_with_index do |ha,i|
				ha[1] = ha[1].to_a
				query_tag = []
				ha[1].each do |v|
					key_values["-q#{counter}"] = ha[0]
					key_values["-q#{counter}.value"] = v
					query_tag << "q#{counter}"
					counter += 1
				end
				query_map << query_tag
			end
			return key_values, query_map
		end

		# Build query request logic for FMP requests  '-query...'
		def array_mix(ary, line=[], rslt=[])
			ary[0].to_a.each_with_index do |v,i|
				array_mix(ary[1,ary.size], (line + [v]), rslt)
				rslt << (line + [v]) if ary.size == 1
			end
			return rslt
		end

		# Translate query request logic to string
		def query_translate(mixed_ary)
			rslt = ""
			sub = mixed_ary.collect {|a| "(#{a.join(',')})"}
			sub.join(";")
		end

	end # ComplexQuery

	#   class Layout
	#   	require 'rfm/layout'
	#     include ComplexQuery
	#   end
  
end # Rfm
