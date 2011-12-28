module Rfm

	# Top level config hash accepts any defined config parameters,
	# or group-name keys pointing to config subsets.
	# The subsets can be any grouping of defined config parameters, as a hash.
	# See CONFIG_KEYS for defined config parameters.
	#
	# All filters are honored, unless filters are included in calls to get_config,
	# in which case only the immediately specified filters will be used.
	#
	# Do not put a :use=>:group filter in a subset (maybe future feature?).
	# Do not put a :use=>:group filter in the top-level global parameters.
	# Do not put subsets in non-top-level configs. (maybe future feature?)
	#
  module Config
  	require 'yaml'
  	
  	CONFIG_KEYS = %w(file_name file_path parser host port account_name password database layout ssl root_cert root_cert_name root_cert_path warn_on_redirect raise_on_401 timeout log_actions log_responses log_parser use parent)

    extend self
    @config = {}		
	  	  
	  # Set @config with args & options hash.
	  # Args should be symbols representing configuration groups,
	  # with optional config hash as last arg, to be merged on top.
	  # Returns @config.
	  #
	  # == Sets @config with :use => :group1, :layout => 'my_layout'
	  #    config :group1, :layout => 'my_layout
	  #
	  # Factory.server, Factory.database, Factory.layout, and Base.config can take
	  # a string as the first argument, refering to the relevent server/database/layout name.
	  #
	  # == Pass a string as the first argument, to be used in the immediate context
	  #    config 'my_layout'                     # in the model, to set model configuration
	  #    Factory.layout 'my_layout', :my_group  # to get a layout from settings in :my_group
	  #
	  def config(*args, &block)
	  	opt = args.rfm_extract_options!
	  	@config ||= {}
			config_write(opt, args, &block)
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
	  #
	  # == Gets top level settings, merged with group settings, merged with local and ad-hoc settings.
	  #    get_config :my_server_group, :layout => 'my_layout'  # This gets top level settings,
		#
		# == Gets top level settings, merged with local and ad-hoc settings.
		#    get_config :layout => 'my_layout
		#
  	def get_config(*args)
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
  		  
	protected
	
		# Get or load a config file as the top-level config (above RFM_CONFIG constant).
		# Default file name is rfm.yml.
		# Default paths are '' and 'config/'.
		# File name & paths can be set in RFM_CONFIG and Rfm.config.
		# Change file name with :file_name => 'something.else'
		# Change file paths with :file_path => ['array/of/', 'file/paths/']
		def get_config_file
			@@config_file_data ||= (
				config_file_name = @config[:file_name] || (RFM_CONFIG[:file_name] rescue nil) || 'rfm.yml'
				config_file_paths = [''] | (@config[:file_path] || (RFM_CONFIG[:file_path] rescue nil) || %w( config/ ))
				config_file_paths.collect do |f|
					(YAML.load_file("#{f}#{config_file_name}") rescue {})
				end.inject({}){|h,a| h.merge(a)}
			) || {}
		end
	  
	  
		# Merge args into @config, as :use=>[arg1, arg2, ...]
		# Then merge optional config hash into @config.
		# Pass in a block to use with strings in args. See base.rb.
	  def config_write(opt, args)
	  	strings = []; while args[0].is_a?(String) do; strings << args.shift; end
	  	args.each{|a| @config.merge!(:use=>a.to_sym)}
	  	@config.merge!(opt)
	  	yield(strings) if block_given?
	  end
	  	
	  # Get composite config from all levels, adding :use parameters to a
	  # temporary top-level value.
	  def config_merge_with_parent
      remote = if (self != Rfm::Config) 
      	eval(@config[:parent] || 'Rfm::Config').config_merge_with_parent rescue {}
      else
      	get_config_file.merge((defined?(RFM_CONFIG) and RFM_CONFIG.is_a?(Hash)) ? RFM_CONFIG : {})
      end
      
      use = (remote[:use].rfm_force_array | @config[:use].rfm_force_array).compact
			remote.merge(@config).merge(:use=>use)
    end	  

		# Given config hash, return filtered. Filters should be symbols.
		def config_filter(conf, filters=nil)
			filters ||= conf[:use].rfm_force_array if !conf[:use].blank?
			filters.each{|f| next unless conf[f]; conf.merge!(conf[f] || {})} if !filters.blank?
			conf.reject!{|k,v| !CONFIG_KEYS.include?(k.to_s) or v.to_s == '' }
			conf
		end
    
    # This loads RFM_CONFIG into @config. It is not necessary,
    # as get_config will merge all configuration into RFM_CONFIG at runtime.
    #config RFM_CONFIG if defined? RFM_CONFIG

	end # module Config
	
end # module Rfm