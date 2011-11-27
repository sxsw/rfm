module Rfm

  
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
	  
	  
		# 	  # Get composite config from all levels
		# 	  def config_get_merged
		# 	    #puts "config_get_merged: #{self.to_s rescue ''} #{superclass.to_s rescue ''}"
		# 	    rfm_config   = (Rfm.config_get_merged rescue {})
		#       class_config = (self.class.config_get_merged rescue {})
		#       super_config = (self.superclass.config_get_merged rescue {})
		#       local_config = (@config rescue {})
		#       remote = Hash.new.merge!(rfm_config).merge!(class_config).merge!(super_config)
		#       (remote = remote[@config[:use]]) if @config.has_key?(:use)
		#       remote.merge!(local_config)
		#     end
	  
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
    
		#     def self.included(base)
		#     	base.extend self
		#     end
    
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