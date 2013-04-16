# The classes in this module are used internally by RFM and are not intended for outside
# use.
#
# Author::    Geoff Coffey  (mailto:gwcoffey@gmail.com)
# Copyright:: Copyright (c) 2007 Six Fried Rice, LLC and Mufaddal Khumri
# License::   See MIT-LICENSE for details


module Rfm

  module Factory
  	# Acquired from Rfm::Base
  	@models ||= []
  	
  	extend Config
  	config :parent=>'Rfm::Config'
  
  	class ServerFactory < Rfm::CaseInsensitiveHash
      
      def [](*args)
      	options = Factory.get_config(*args)
      	host = options[:strings].delete_at(0) || options[:host]
        super(host) or (self[host] = Rfm::Server.new(host, options.rfm_filter(:account_name, :password, :delete=>true)))
        # This part reconfigures the named server, if you pass it new config in the [] method.
        # This breaks some specs in all [] methods in Factory. Consider undoing this. See readme-dev.
				#   super(host).config(options) if (options)
				#   super(host)
      end
			
			# Potential refactor
			# 		def [](*conf)
			# 			options = Factory.get_config(*conf)
			#   		server_name = options[:strings][0] || options[:host]
			#   		options[:host] = server_name
			# 			#server = servers[server_name, options]
			# 			super(server_name) or (self[server_name] = Rfm::Server.new(options.reject{|k,v| [:account_name, :password].include? k}))
			# 		end
    
    end # ServerFactory
    
    
    class DbFactory < Rfm::CaseInsensitiveHash # :nodoc: all
    
      def initialize(server)
        @server = server
        @loaded = false
      end
      
      def [](*args)
      	# was: (dbname, acnt=nil, pass=nil)
      	options = Factory.get_config(*args)
      	name = options[:strings].delete_at(0) || options[:database]
      	account_name = options[:strings].delete_at(0) || options[:account_name]
      	password = options[:strings].delete_at(0) || options[:password]
        super(name) or (self[name] = Rfm::Database.new(name, account_name, password, @server))
        # This part reconfigures the named database, if you pass it new config in the [] method.
				#   super(name).config({:account_name=>account_name, :password=>password}.merge(options)) if (account_name or password or options)
				#   super(name)
      end
      
      def all
        if !@loaded
					c = Connection.new('-dbnames', {}, {:grammar=>'FMPXMLRESULT'}, :parent=>@server)
					c.parse('fmpxml_databases.yml', {})['DATA'].each{|k,v| self[k] = Rfm::Database.new(v['text'], @server)}
          @loaded = true
        end
        self
      end
      
      def names
      	#keys
      	self.values.collect{|v| v.name}
      end
    
    end # DbFactory
    
    
    
    class LayoutFactory < Rfm::CaseInsensitiveHash # :nodoc: all
    	
      def initialize(server, database)
        @server = server
        @database = database
        @loaded = false
      end
      
      def [](*args) # was layout_name
      	options = Factory.get_config(*args)
      	name = options[:strings].delete_at(0) || options[:layout]
        super(name) or (self[name] = Rfm::Layout.new(name, @database, options))
        # This part reconfigures the named layout, if you pass it new config in the [] method.
				#   super(name).config({:layout=>name}.merge(options)) if options
				#   super(name)
      end
      
      def all
        if !@loaded
# 	        get_layout_names.each {|record|
# 	          name = record['LAYOUT_NAME']
# 	        	begin
# 	          	(self[name] = Rfm::Layout.new(name, @database)) unless !self[name].nil? or name.to_s.strip == ''
# 	          rescue
# 	          	$stderr.puts $!
# 	          end
# 	        }
					c = Connection.new('-layoutnames', {"-db" => @database.name}, {:grammar=>'FMPXMLRESULT'}, :parent=>@database)
					#c.parse('fmpxml_layouts.yml', {})['DATA'].each{|k,v| self[k] = Rfm::Layout.new(v['text'], @database)}
					return c.parse({}, {})  #['DATA'].each{|k,v| self[k] = Rfm::Layout.new(v['text'], @database)}
          @loaded = true
        end
        self
      end
      
      def get_layout_names_xml
      	@server.connect(@database.account_name, @database.password, '-layoutnames', {"-db" => @database.name})
      end
      
      def get_layout_names
      	#Rfm::Resultset.new(@server, get_layout_names_xml.body, nil)
      	Rfm::Resultset.new(get_layout_names_xml.body, :database_object => @database)
      end
    
    	def names
    		keys
    	end
    	
    	# Acquired from Rfm::Base
    	def modelize(filter = /.*/)
    		all.values.each{|lay| lay.modelize if lay.name.match(filter)}
    		models
    	end
    	
    	# Acquired from Rfm::Base
    	def models
	    	rslt = {}
    		each do |k,lay|
    			layout_models = lay.models
    			rslt[k] = layout_models if (!layout_models.nil? && !layout_models.empty?)
	    	end
	    	rslt
    	end
    	
    end # LayoutFactory
    
    
    
    class ScriptFactory < Rfm::CaseInsensitiveHash # :nodoc: all
    
      def initialize(server, database)
        @server = server
        @database = database
        @loaded = false
      end
      
      def [](script_name)
        super or (self[script_name] = Rfm::Metadata::Script.new(script_name, @database))
      end
      
      def all
        if !@loaded
        	xml = @server.connect(@database.account_name, @database.password, '-scriptnames', {"-db" => @database.name}).body
          Rfm::Resultset.new(xml, :database_object => @database).each {|record|
            name = record['SCRIPT_NAME']
            self[name] = Rfm::Metadata::Script.new(name, @database) if self[name] == nil
          }
          @loaded = true
        end
        self
      end
 
 			def names
 				keys
 			end
    
    end # ScriptFactory
    
    
    
    class << self
    
    	# Acquired from Rfm::Base
  		attr_accessor :models
	  	# Shortcut to Factory.db().layouts.modelize()
	  	# If first parameter is regex, it is used for modelize filter.
	  	# Otherwise, parameters are passed to Factory.database
	  	def modelize(*args)
	  		regx = args[0].is_a?(Regexp) ? args.shift : /.*/
	  		db(*args).layouts.modelize(regx)
	  	end
    	
			def servers
				@servers ||= ServerFactory.new
			end    
    
	  	# Returns Rfm::Server instance, given config hash or array
	  	def server(*conf)
	  		options = get_config(*conf)
				#server = servers[server_name, options]
				# These disconnect servers from the ServerFactory hash, but it breaks the ActiveModel spec suite.
				#Rfm::Server.new(server_name, options.rfm_filter(:account_name, :password, :delete=>true))
				Rfm::Server.new(options)
		  end
			# Potential refactor
			#def_delegator 'Rfm::Factory::ServerFactory', :[], :server  #, :[]
	  
		  # Returns Rfm::Db instance, given config hash or array
		  def db(*conf)
		  	options = get_config(*conf)
		  	name = options[:strings].delete_at(0) || options[:database]
		  	account_name = options[:strings].delete_at(0) || options[:account_name]
		  	password = options[:strings].delete_at(0) || options[:password]
				s = server(options)
				#puts "Creating db object in Factory.db. Options: #{options.to_yaml}"
				s[name, account_name, password, options]
		  end
		  
		  alias_method :database, :db
		  
		  # Returns Rfm::Layout instance, given config hash or array
	  	def layout(*conf)
	  		options = get_config(*conf)
	  		name = options[:strings].delete_at(0) || options[:layout]
				d = db(options)
				d[name, options]
	  	end

    end # class << self
    
  end # Factory
end # Rfm