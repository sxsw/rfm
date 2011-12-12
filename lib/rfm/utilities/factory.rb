# The classes in this module are used internally by RFM and are not intended for outside
# use.
#
# Author::    Geoff Coffey  (mailto:gwcoffey@gmail.com)
# Copyright:: Copyright (c) 2007 Six Fried Rice, LLC and Mufaddal Khumri
# License::   See MIT-LICENSE for details


module Rfm

  module Factory 
  	extend Config
  	config :parent=>'Rfm::Config'
  
  	class ServerFactory < Rfm::CaseInsensitiveHash # @private :nodoc: all
      
      def [](host, conf = (Factory.instance_variable_get(:@config) || {}))
        super(host) or (self[host] = Rfm::Server.new(conf.reject{|k,v| [:account_name, :password].include? k}))
      end
    
    end # ServerFactory
    
    
    class DbFactory < Rfm::CaseInsensitiveHash # :nodoc: all
    
      def initialize(server)
        @server = server
        @loaded = false
      end
      
      def [](dbname, acnt=nil, pass=nil) #
        db = (super(dbname) or (self[dbname] = Rfm::Database.new(dbname, @server)))
        account_name = acnt || db.account_name || @server.state[:account_name]
        password = pass || db.password || @server.state[:password]
        db.account_name = account_name if account_name
        db.password = password if password
        db
      end
      
      def all
        if !@loaded
          Rfm::Resultset.new(@server, @server.connect(@server.state[:account_name], @server.state[:password], '-dbnames', {}).body, nil).each {|record|
            name = record['DATABASE_NAME']
            self[name] = Rfm::Database.new(name, @server) if self.keys.find{|k| k.to_s.downcase == name.to_s.downcase} == nil
          }
          @loaded = true
        end
        self
      end
      
      def names
      	keys
      end
    
    end # DbFactory
    
    class LayoutFactory < Rfm::CaseInsensitiveHash # :nodoc: all
    
      def initialize(server, database)
        @server = server
        @database = database
        @loaded = false
      end
      
      def [](layout_name)
        super or (self[layout_name] = Rfm::Layout.new(layout_name, @database))
      end
      
      def all
        if !@loaded
	        Rfm::Resultset.new(@server, @server.connect(@database.account_name, @database.password, '-layoutnames', {"-db" => @database.name}).body, nil).each {|record|
	          name = record['LAYOUT_NAME']
	          self[name] = Rfm::Layout.new(name, @database) if self[name] == nil
	        }
          @loaded = true
        end
        self
      end
    
    	def names
    		keys
    	end
    	
    	def modelize(filter = /.*/)
    		all.values.each{|lay| lay.modelize if lay.name.match(filter)}
    		models
    	end
    	
    	def models
    		values.collect{|lay| lay.model}.compact
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
          Rfm::Resultset.new(@server, @server.connect(@database.account_name, @database.password, '-scriptnames', {"-db" => @database.name}).body, nil).each {|record|
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
    	attr_accessor :models
    
			def servers
				@servers ||= Factory::ServerFactory.new  #(config_read)
			end    
    
	  	# Returns Rfm::Server instance, given config hash or array
	  	def server(*conf)
	  		options = config_read(*conf)
	  		server_name = options[:strings][0] || options[:host]
				server = servers[server_name, options]
		  end
	  
		  # Returns Rfm::Db instance, given config hash or array
		  def db(*conf)
	  		options = config_read(*conf)
	  		db_name = options[:strings][0] || options[:database]
	  		account_name = options[:strings][1] || options[:account_name]
	  		password = options[:strings][2] || options[:password]
				db = server(options)[db_name, account_name, password]
		  end
		  
		  alias_method :database, :db
		  
		  # Returns Rfm::Layout instance, given config hash or array
	  	def layout(*conf)
	  		options = config_read(*conf)
	  		layout_name = options[:strings][0] || options[:layout]
				layout = db(options)[layout_name]
	  	end
	  	
	  	# Shortcut to Factory.db().layouts.modelize()
	  	# If first parameter is regex, it is used for modelize filter.
	  	# Otherwise, parameters are passed to Factory.database
	  	def modelize(*args)
	  		regx = args[0].is_a?(Regexp) ? args.shift : /.*/
	  		db(*args).layouts.modelize(regx)
	  	end
    
    end # class << self
    @models ||= []
    
  end # Factory
end # Rfm