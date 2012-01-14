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
  
  	class ServerFactory < Rfm::CaseInsensitiveHash
      
      def [](host, conf = Factory.get_config) #(Factory.instance_variable_get(:@config) || {}))
      	conf[:host] = host
        super(host) or (self[host] = Rfm::Server.new(conf.reject{|k,v| [:account_name, :password].include? k}))
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
	        get_layout_names.each {|record|
	          name = record['LAYOUT_NAME']
	        	begin
	          	(self[name] = Rfm::Layout.new(name, @database)) unless !self[name].nil? or name.to_s.strip == ''
	          rescue
	          	$stderr.puts $!
	          end
	        }
          @loaded = true
        end
        self
      end
      
      def get_layout_names_xml
      	@server.connect(@database.account_name, @database.password, '-layoutnames', {"-db" => @database.name})
      end
      
      def get_layout_names
      	Rfm::Resultset.new(@server, get_layout_names_xml.body, nil)
      end
    
    	def names
    		keys
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
    	
			def servers
				@servers ||= ServerFactory.new
			end    
    
	  	# Returns Rfm::Server instance, given config hash or array
	  	def server(*conf)
	  		options = get_config(*conf)
	  		server_name = options[:strings][0] || options[:host]
	  		raise Rfm::Error::RfmError.new(0, 'A host name is needed to create a server object.') if server_name.blank?
				server = servers[server_name, options]
		  end
			# Potential refactor
			#def_delegator 'Rfm::Factory::ServerFactory', :[], :server  #, :[]
	  
		  # Returns Rfm::Db instance, given config hash or array
		  def db(*conf)
	  		options = get_config(*conf)
	  		db_name = options[:strings][0] || options[:database]
	  		raise Rfm::Error::RfmError.new(0, 'A database name is needed to create a database object.') if db_name.blank?
	  		account_name = options[:strings][1] || options[:account_name]
	  		password = options[:strings][2] || options[:password]
				db = server(options)[db_name, account_name, password]
		  end
		  
		  alias_method :database, :db
		  
		  # Returns Rfm::Layout instance, given config hash or array
	  	def layout(*conf)
	  		options = get_config(*conf)
	  		layout_name = options[:strings][0] || options[:layout]
	  		raise Rfm::Error::RfmError.new(0, 'A layout name is needed to create a layout object.') if layout_name.blank?
				layout = db(options)[layout_name]
	  	end

    end # class << self
    
  end # Factory
end # Rfm