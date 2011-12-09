module Rfm

	### Main config should be a hash of hashes, so that each key (nickname) will be unique.
	### Top level global config hash accepts any defined config parameters
	### or group-name keys pointing to config subsets.
	### The subsets can be any grouping of config parameters, as a hash.
	### Some config parameters are global only, and most are only relevant within specific contexts.
	### See <...>
	
  
  # Methods to be included and/or extended into RfmHelper::Base
  # All included methods are also extended
  module Config
    extend self
    
    # Sets @config with args. Two use forms:
    # config :key_name, :hash_item=>'', :hash_item2=>
    # config :key_name=>{:some=>'hash',...}, :key_name2=>{:someother=>'hash',...}
    # password will always be 'protected'
    def config(*args)
	    c = config_core(*args)
	    c[:password] = 'PROTECTED' if c[:password]
	    c
	  end
	  
	protected
	  
	  # Unsecure, will return raw password
	  def config_core(*args)
	    @config ||= {}
	    @config.merge!(config_merge_args(@config, args))
	    config_get_merged
	  end
	  
	  # Get composite config from all levels
	  def config_get_merged
      remote = (eval(@config[:parent]).config_get_merged rescue {})
      (remote = remote[@config[:use]]) if @config.has_key?(:use)
      #puts "remote_config: #{remote.class}"
			Hash.new.merge!(remote).merge!(@config) rescue {}
    end	  
	  
	  # Returns dup of conf with merged args
	  def config_merge_args(conf, args)
	    conf = conf.dup
  	  if args && args.class == Array
	  	  if args.size == 1
	  	  	if args[0].is_a? Symbol
	  	  		conf.merge!({:use=>args[0]})
	  	  	else
	  	    	conf.merge! args[0]
	  	    end
	  	  elsif args && args.size == 2
	  	    name = args.shift
	  	    conf.merge!({name=>args[0]})
	      end
  	  elsif args && args.class == Hash
  	    conf.merge!(args)
      end
      ###	    
      return conf
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