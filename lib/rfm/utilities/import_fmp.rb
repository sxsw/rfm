module Rfm

  module ImportFmp # @private :nodoc: all
    # TODO: fix mysql_import to be module & include it here
  	# See config/mysql_import.rb
  	# args: time-since-modified-as-anything, mapping-name, options-hash
  	# options-hash:  :modified_since=>time-as-anything, :mapping=>full-mapping, :layout=>fmp-layout-name, :fields=>{bb_field=>mysql_field}
  	# block: any code that returns rfm records, will be passed |var|
  	# result: [rmf_found_size, message, rfm_found_records]
  	def import_fmp_core(*args, &block)
  		log "import_fmp_core begin", table_name
  		options = args.extract_options! # See extract_options.rb when the Rails method becomes deprecated (2.3.8?)
  		modified_since =args[0] || options[:modified_since] || (Time.now - 2.hours)
  		modified_since_s = Time.parse(modified_since.to_s).strftime('%m/%d/%Y %T')
  		# Convert dates & times
  		mod_date_since, mod_time_since = Time.parse(modified_since.to_s).to_fm_components(true)
  		# Import field map
  		mapping = (mappings[args[1]] || options[:mapping] || mappings[:fm_import])
  		# Filemaker data
  		layout = options[:layout] || mapping[:layout]
  		fields = options[:fields] || mapping[:fields]
  		log("import_fmp_core", [options, args].to_yaml) if (Rails.logger.level == 0 and RAILS_ENV == :development)
  		if modified_since == 'all'
  			records = fm(layout).all
  		else
  			records = eval(block.call)
  		end
  		log "import_fmp_core found records", records.size
  		# Perform import, get [count, message] in return
  		rslt = self.import(fields, records, {:update=>true})
  		log "import_fmp_core end", table_name
  		# Return result
  		return (rslt << records)
  	end
  	alias_method :import_bb_core, :import_fmp_core
  	
  end # module ImportFmp
  
	#   # This is now in core_ext
	#   class ::Time
	#   	# Returns array of [date,time] in format suitable for FMP.
	#   	def to_fm_components(reset_time_if_before_today=false)
	#   		d = self.strftime('%m/%d/%Y')
	#   		t = if (Date.parse(self.to_s) < Date.today) and reset_time_if_before_today==true
	#   			"00:00:00"
	#   		else
	#   			self.strftime('%T')
	#   		end
	#   		[d,t]
	#   	end
	#   end
  

  ### Enable this or put this in main_initializer to add ImportFmp to ActiveRecord models....
  # class ActiveRecord::Base
  #   require 'mysql_import'  # fix mysql_import to be module and include it above.
  #   extend ImportFmp
  # end
  
end # Rfm