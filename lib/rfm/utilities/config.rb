module Rfm

	# Top level config hash accepts any defined config parameters,
	# or group-name keys pointing to config subsets.
	# The subsets can be any grouping of config parameters, as a hash.
	# 
	# Potential future enhancement:
	#
	# 		Top level may contain a :global group, which will always be included in compiled configs.
	# 		
	# 		Top level may also contain basic config parameters, which will be read if no filters
	# 		are encountered in any :use parameter. These default parameters will be included
	# 		if a :use=>:default is encountered in compilation.
	#
	# All filters are honored, unless filters are included in method parameter calls to config_all,
	# in which case, only the passed-in filters will be used.
	#
	# Do not put a :use parameter in a subset (maybe future feature?).
	# Do not put a :use parameter in the top-level global parameters.
	# Do not put subsets in non-top-level configs.
	#
  module Config
  	KEYS = %w(parser host port account_name password database layout ssl root_cert root_cert_name root_cert_path warn_on_redirect raise_on_401 timeout log_actions log_responses log_parser use parent)

    extend self
	  	  
	  # Set @config with args & options hash.
	  # Args should be symbols representing configuration groups,
	  # with optional config hash as last arg, to be merged on top.
	  # Returns @config.
	  def config(*args)
	  	opt = args.rfm_extract_options!
	  	@config ||= {}
			config_write(opt, args)
			@config
	  end
	  
	  # Sets @config just as above config method, but clears @config first.
	  def config_clear(*args)
	  	opt = args.rfm_extract_options!
	  	@config = {}
			config_write(opt, args)
			@config
	  end
	  
	  # Reads compiled config, including filters and ad-hoc configuration params passed in.
	  # If first n parameters are strings, they will be appended to config[:strings].
	  # If next n parameters are symbols, they will be used to filter the result. These
	  # filters will override all stored config[:use] settings.
	  # The final optional hash should be ad-hoc config settings.
  	def config_all(*args)
  		@config ||= {}
  		opt = args.rfm_extract_options!
  		strings = []
  		while args[0].is_a?(String) do; strings << args.shift; end
	    if args.size == 0
	    	config_filter(config_merge_with_parent)
	    else
	    	config_filter(config_merge_with_parent, args)
	    end.merge(opt).merge(:strings=>strings)
  	end
  	
  	alias_method :get_config, :config_all
	  
	protected
	  
	  
		# Merge args into @config, as :use=><each_arg>.
		# Then merge optional config hash into @config. 	
	  def config_write(opt, args)
	  	args.each{|a| @config.merge!(:use=>a.to_sym)}
	  	@config.merge!(opt)
	  end
	  	
	  # Get composite config from all levels, adding :use parameters to a
	  # temporary top-level value.
	  def config_merge_with_parent
      remote = (eval(@config[:parent]).config_merge_with_parent rescue {})
      use = (remote[:use].rfm_force_array | @config[:use].rfm_force_array).compact
			remote.merge(@config).merge(:use=>use)
    end	  

		# Given config hash, return filtered. Filters should be symbols.
		def config_filter(conf, filters=nil)
			filters ||= conf[:use].rfm_force_array
			filters.each{|f| conf.merge!(conf[f] || {})}
			conf.reject!{|k,v| !KEYS.include?(k.to_s) or v.to_s == '' }
		end
    
		#     def extended(base)
		#     	base.config :parent=>self.to_s
		#     end
    
    config RFM_CONFIG if defined? RFM_CONFIG

	end # module Config
	
end # module Rfm