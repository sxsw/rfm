module Rfm
	module XmlParser
		require 'rubygems'
		require 'active_support/xml_mini'
		
		attr_reader :backend
		
		def self.backend_modules(name)
			{:jdom=>'JDOM', :libxml=>'LibXML', :libxmlsax=>'LibXMLSAX', :nokogiri=>'Nokogiri', :nokogirisax=>'NokogiriSAX', :rexml=>'REXML'}[name]
		end
		
		def self.select_backend
			begin
				require 'jdom'
				@backend = :jdom
			rescue
				require 'libxml'
				@backend = :libxml
			rescue LoadError
				require 'nokogiri'
				@backend = :nokogirisax
			rescue LoadError
				@backend = :rexml
			end
			backend_modules(@backend)
		end

		def self.new(string_or_file, opts={})
			string_or_file.gsub!(/xmlns=\"[^\"]*\"/,'') if (string_or_file.class == String and opts[:namespace] == false)
			ActiveSupport::XmlMini.with_backend(backend_modules(opts[:backend] || @backend)) do
				ActiveSupport::XmlMini.parse(string_or_file)
			end
		end
		
		class ::Hash
			def ary
				[self]
			end
		end
		
		class ::Array
			def ary
				self
			end
		end	 
		
		select_backend
		
	end
end



### Old Code for Other Parsers ###

#		begin
# 		require 'nokogiri'
# 		puts "Using Nokogiri"
# 		@parser = proc{|*args| Nokogiri.XML(*args)}
# 	rescue LoadError
# 		require 'ox'
# 		@parser = proc{|*args| }
# 	rescue LoadError
# 		require 'libxml'
# 		@parser = proc{|*args| LibXML::XML::Parser.string(*args).parse}
# 	rescue LoadError
# 		require 'hpricot'
# 		Hpricot::Doc.class_eval{alias_method :xpath, :search}
# 		Hpricot::Elements.class_eval{alias_method :xpath, :search}
# 		@parser = proc{|*args| Hpricot.XML(*args)}
# 	rescue LoadError
# 		require 'rexml/document'
# 		puts "Using REXML"
# 		REXML::Element.class_eval{def xpath(str); self.elements[str]; end}
# 		@parser = proc{|*args| REXML::Document.new(*args)}
# 	rescue LoadError
# 		require 'multi_xml'
# 		@parser = proc{|*args| MultiXml.parser = :ox; MultiXml.parse(*args)}
# 	rescue LoadError
# 		require 'active_support/xml_mini'
# 		@parser = proc{|*args| ActiveSupport::XmlMini.backend = 'LibXMLSAX'; ActiveSupport::XmlMini.parse(*args)}
#		end
# 
# 	def self.new(*args)
# 		opts = args.pop if args.last.is_a? Hash
# 		args[0].gsub!(/xmlns=\"[^\"]*\"/,'') if (args[0].class == String and opts[:namespace] == false)
# 		@parser.call(args)
# 	end