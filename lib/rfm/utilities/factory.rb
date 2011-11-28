# The classes in this module are used internally by RFM and are not intended for outside
# use.
#
# Author::    Geoff Coffey  (mailto:gwcoffey@gmail.com)
# Copyright:: Copyright (c) 2007 Six Fried Rice, LLC and Mufaddal Khumri
# License::   See MIT-LICENSE for details


module Rfm

  module Factory # :nodoc: all
  	extend Config
  	config :parent=>'Rfm::Config'
  
  	class ServerFactory < Rfm::CaseInsensitiveHash
    
			#       def initialize(conf=)
			#       	@conf = conf
			#       	if conf
			#       		(config.is_a?(Hash) ? [config] : config).each do |cnf|
			#       			self[cnf[:nickname]] = Rfm::Server.new(cnf) if cnf[:nickname]
			#       		end
			#       	end
			#         @loaded = true
			#       end
      
      def [](host, conf = config_core)
        super(host) or (self[host] = Rfm::Server.new(conf))
      end
    
    end # ServerFactory
    
    class DbFactory < Rfm::CaseInsensitiveHash
    
      def initialize(server)
        @server = server
        @loaded = false
      end
      								#account_name= @server.state[:account_name], password= @server.state[:password]
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
        self.keys
      end
    
    end
    
    class LayoutFactory < Rfm::CaseInsensitiveHash
    
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
	          self[name] = Rfm::Layout.new(name, @database) #if self[name] == nil
	        }
          @loaded = true
        end
        self.keys
      end
    
    end
    
    class ScriptFactory < Rfm::CaseInsensitiveHash
    
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
        self.keys
      end
    
    end # ScriptFactory
    
    class << self
    
			def servers
				@servers ||= Factory::ServerFactory.new  #(config_core)
			end    
    
	  	# Returns RFM server object, given config hash
	  	def server(conf = config_core)
	      server_name = conf[:host]
	  	  server = servers[server_name, conf]
		  end
	  
		  # Returns RFM db object, given config hash
		  def db(conf = config_core)
				db_name = conf[:database]
				db = server(conf)[db_name]
		  end
		  
		  # Returns RFM layout object, given config hash
	  	def layout(conf = config_core)
	  		#return @layout if (@layout and args==[])
	  		#opt = args.last.is_a?(Hash) ? args.pop : {}
	  	  layout_name = conf[:layout]
	      return {:error=>'Failed to get layout name', :conf=>conf} unless layout_name
				layout = db(conf)[layout_name]
	  	end
    
    end # class << self
  end # Factory
end # Rfm