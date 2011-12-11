module Rfm

	# Main config should be a hash of hashes, so that each key (nickname) will be unique.
	# Top level global config hash accepts any defined config parameters,
	# or group-name keys pointing to config subsets.
	# The subsets can be any grouping of config parameters, as a hash.
	# Some config parameters are global only, and most are only relevant within specific contexts.
  module Config
    extend self
    
    # Sets @config with args. Two use forms:
    # 1. Pass only a hash to SET config.
    # 2. Pass an array, with optional hash as last element, to GET config.
    # Array items should be symbols representing config groups to merge.
    # config :group_name, :hash_item=>'', :hash_item2=>...
    # config :key_name=>value, :key_name2=>value2
    # password will always return 'protected'
		#     def config(*args)
		# 	    c = config_core(*args)
		# 	    c[:password] = 'PROTECTED' if c[:password]
		# 	    c
		# 	  end
	  	  
	  def config(*args)
	  	opt = args.rfm_extract_options!
	  	@config ||= {}
			config_write(opt, args)
			config_get_all
	  end
	  
	  def config_clear(*args)
	  	opt = args.rfm_extract_options!
	  	@config = {}
			config_write(opt, args)
			config_get_all
	  end
	  	  
  	def config_read(*args)
  		@config ||= {}
  		opt = args.rfm_extract_options!
  		string = args[0].is_a?(String) ? args.shift : nil
	    if args.size == 0
	    	config_get_all(@config[:use])
	    else
	    	config_get_all(args)
	    end.merge(opt).merge(:string=>string)
  	end	  	
	  
	protected
	  
	  # Core config method. Unsecure, will return raw password.
		# 	  def config_core(*args)
		# 	  	opt = args.rfm_extract_options!
		# 	    @config ||= {}
		# 	    if args.size == 0
		# 	    	@config.merge!(opt)
		# 	    	config_get_all(@config[:use])
		# 	    else
		# 	    	config_get_all(args).merge(opt)
		# 	    end.dup
		# 	  end	  	  	  
	 	
	  def config_write(opt, args)
	  	args.each{|a| @config.merge!(:use=>a.to_sym)}
	  	@config.merge!(opt)
	  end
	  	
	  		  
	  # Get composite config from all levels.
	  # Pass in group names as symbols to filter result.
	  def config_get_all(filters=nil)
      remote = (eval(@config[:parent]).config_get_all rescue {})
      #(remote = remote[@config[:use]]) if @config.has_key?(:use)
      #puts "remote_config: #{remote.class}"
			config_filter((Hash.new.merge!(remote)), filters).merge!(@config)
    end	  

		# Given config hash, return filtered.
		def config_filter(conf, filters)
			return conf unless filters
			return conf[filters] if filters.is_a? Symbol
			rslt = {}
			#conf.each {|k,v| rslt.merge!(v) if filters.include? k}
			filters.each{|f| rslt.merge!(conf[f] || {})}
			rslt
		end
    
    def inherited(base)
    	base.config :parent=>self.to_s
    end
    
    config RFM_CONFIG if defined? RFM_CONFIG

	end # module Config
	
	# 	include Config
	# 	config RFM_CONFIG if defined? RFM_CONFIG
	def self.config(*args)
		Config.config(*args)
	end
	
end # module Rfm