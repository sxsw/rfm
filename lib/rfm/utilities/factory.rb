# The classes in this module are used internally by RFM and are not intended for outside
# use.
#
# Author::    Geoff Coffey  (mailto:gwcoffey@gmail.com)
# Copyright:: Copyright (c) 2007 Six Fried Rice, LLC and Mufaddal Khumri
# License::   See MIT-LICENSE for details


module Rfm

	def self.servers
		@servers ||= Factory::ServerFactory.new(RFM_CONFIG)
	end

  module Factory # :nodoc: all
  
  	### Main config should be a hash of hashes, so that each key (nickname) will be unique.
  	class ServerFactory < Rfm::CaseInsensitiveHash
    
      def initialize(config=nil)
      	@config = config
      	if config
      		(config.is_a?(Hash) ? [config] : config).each do |cnf|
      			self[cnf[:nickname]] = Rfm::Server.new(cnf) if cnf[:nickname]
      		end
      	end
        @loaded = true
      end
      
      def [](nickname, config = @config)
        super(nickname) or (self[nickname] = Rfm::Server.new(config))
      end
    
    end
    
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
	          self[name] = Rfm::Layout.new(name, @database) if self[name] == nil
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
    
    end
  end
end